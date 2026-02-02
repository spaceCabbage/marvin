#!/usr/bin/env python3
"""
Marvin Telegram Bot
===================
Telegram frontend for the Marvin security research platform.
Bridges messages to Claude Code CLI running inside the Marvin container.

Architecture:
- Runs as a separate container alongside marvin-vm
- Uses `docker exec` to invoke `claude -p` inside the Marvin container
- Shares the workspace volume for file access
- Exposes an internal HTTP API (port 8443) for the Telegram MCP server
  running inside the Marvin container, enabling Claude to ask the user
  questions mid-execution and send files directly

Features:
- Full Claude Code session management (new, resume, continue)
- Rich media handling (photos, documents, voice, location, contacts)
- Streaming output with live progress updates
- MCP bridge: Claude can call telegram_ask / telegram_send_file mid-task
- File browsing and sending from engagements
- Auto-detection of new output files after operations
- Authorization control via Telegram user IDs
"""

import os
import json
import asyncio
import logging
import time
import re
from pathlib import Path
from datetime import datetime
from typing import Optional
from dataclasses import dataclass, field

from aiohttp import web
from telegram import (
    Update,
    BotCommand,
    ForceReply,
    InlineKeyboardButton,
    InlineKeyboardMarkup,
    InputFile,
)
from telegram.ext import (
    Application,
    CommandHandler,
    MessageHandler,
    CallbackQueryHandler,
    filters,
    ContextTypes,
)
from telegram.constants import ParseMode, ChatAction


# =============================================================================
# Configuration
# =============================================================================

TELEGRAM_BOT_TOKEN = os.environ["TELEGRAM_BOT_TOKEN"]
MARVIN_CONTAINER = os.environ.get("MARVIN_CONTAINER", "marvin-vm")
WORKSPACE_PATH = os.environ.get("WORKSPACE_PATH", "/workspace")
MCP_API_PORT = int(os.environ.get("MCP_API_PORT", "8443"))
MAX_MSG_LEN = 4096
UPDATE_INTERVAL = 3.0
TYPING_INTERVAL = 4.0
MAX_FILE_BUTTONS = 20
ASK_TIMEOUT = 300           # 5 minutes to answer a question

# Parse allowed Telegram user IDs
ALLOWED_USERS: set[int] = set()
_allowed = os.environ.get("TELEGRAM_ALLOWED_USERS", "")
if _allowed:
    ALLOWED_USERS = {int(x.strip()) for x in _allowed.split(",") if x.strip()}

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
)
log = logging.getLogger("marvin-bot")


# =============================================================================
# Session State
# =============================================================================

@dataclass
class Session:
    """Per-chat Claude session state."""
    session_id: Optional[str] = None
    is_running: bool = False
    current_proc: Optional[asyncio.subprocess.Process] = None
    last_active: datetime = field(default_factory=datetime.now)
    files_before: set[str] = field(default_factory=set)
    message_count: int = 0


# chat_id -> Session
sessions: dict[int, Session] = {}

# File path registry for callback buttons (callback_data has 64 byte limit)
file_registry: dict[str, str] = {}
_file_counter = 0

# MCP pending question state
# When Claude calls telegram_ask via the MCP server, the question is stored
# here. The next user message or inline button press resolves the future.
pending_question: Optional[dict] = None   # {"future", "chat_id", "question"}
mcp_choices: list[str] = []               # choices for current pending question

# Active chat ID for the MCP API (which chat to send messages to)
active_chat_id: Optional[int] = None

# Global bot reference (set during startup for the HTTP API handlers)
bot_app: Optional[Application] = None


def get_session(chat_id: int) -> Session:
    if chat_id not in sessions:
        sessions[chat_id] = Session()
    return sessions[chat_id]


def register_file(path: str) -> str:
    """Register a file path and return a short callback key."""
    global _file_counter
    _file_counter += 1
    key = f"f:{_file_counter}"
    file_registry[key] = path
    return key


# =============================================================================
# Authorization
# =============================================================================

def authorized(func):
    """Decorator to restrict access to allowed Telegram user IDs."""
    async def wrapper(update: Update, context: ContextTypes.DEFAULT_TYPE):
        user = update.effective_user
        if ALLOWED_USERS and user.id not in ALLOWED_USERS:
            await update.message.reply_text(
                f"Access denied. Your user ID: {user.id}\n"
                "Add it to TELEGRAM_ALLOWED_USERS in .env to authorize."
            )
            log.warning(f"Unauthorized access attempt: {user.id} ({user.username})")
            return
        return await func(update, context)
    return wrapper


# =============================================================================
# Utility Functions
# =============================================================================

def scan_workspace_files() -> set[str]:
    """Scan all files under engagements/ in workspace."""
    files = set()
    eng_path = Path(WORKSPACE_PATH) / "engagements"
    if eng_path.exists():
        for f in eng_path.rglob("*"):
            if f.is_file():
                files.add(str(f))
    return files


def split_message(text: str, max_len: int = MAX_MSG_LEN) -> list[str]:
    """Split long text into chunks respecting Telegram's message limit."""
    if len(text) <= max_len:
        return [text]

    parts = []
    while text:
        if len(text) <= max_len:
            parts.append(text)
            break
        idx = text.rfind("\n", 0, max_len)
        if idx < max_len // 4:
            idx = text.rfind(" ", 0, max_len)
        if idx < max_len // 4:
            idx = max_len
        parts.append(text[:idx])
        text = text[idx:].lstrip("\n")
    return parts


def format_for_telegram(text: str) -> str:
    """Convert Claude's markdown to Telegram-safe HTML."""
    text = text.replace("&", "&amp;")
    text = text.replace("<", "&lt;")
    text = text.replace(">", "&gt;")

    # Fenced code blocks -> <pre>
    text = re.sub(
        r"```(?:\w*)\n(.*?)```",
        lambda m: f"<pre>{m.group(1)}</pre>",
        text,
        flags=re.DOTALL,
    )
    # Inline code -> <code>
    text = re.sub(r"`([^`\n]+)`", r"<code>\1</code>", text)
    # Bold
    text = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", text, flags=re.DOTALL)

    return text


async def send_telegram(chat_id: int, text: str, bot, **kwargs):
    """Send a message with HTML, falling back to plain text."""
    formatted = format_for_telegram(text)
    try:
        return await bot.send_message(
            chat_id=chat_id, text=formatted,
            parse_mode=ParseMode.HTML, **kwargs,
        )
    except Exception:
        return await bot.send_message(chat_id=chat_id, text=text, **kwargs)


# =============================================================================
# Claude CLI Bridge
# =============================================================================

async def run_claude(
    message: str,
    session: Session,
    chat_id: int,
    bot,
    status_msg_id: int,
) -> tuple[str, Optional[str], list[str]]:
    """
    Run `claude -p` inside the Marvin container with streaming JSON output.
    Returns (result_text, session_id, tools_used).
    """
    cmd = [
        "docker", "exec", "-i",
        MARVIN_CONTAINER,
        "claude", "-p",
        "--output-format", "stream-json",
        "--verbose",
    ]
    if session.session_id:
        cmd.extend(["--resume", session.session_id])

    log.info(f"Claude exec: chat={chat_id}, resume={session.session_id or 'new'}")

    try:
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
    except Exception as e:
        log.error(f"Failed to start docker exec: {e}")
        return f"Failed to connect to Marvin container: {e}", None, []

    session.current_proc = proc
    session.is_running = True

    # Send message via stdin
    try:
        proc.stdin.write(message.encode("utf-8"))
        await proc.stdin.drain()
        proc.stdin.close()
    except Exception as e:
        log.error(f"Failed to write to claude stdin: {e}")
        session.is_running = False
        session.current_proc = None
        return f"Failed to send message to Claude: {e}", None, []

    result_text = ""
    accumulated_text = ""
    new_session_id = session.session_id
    tools_used = []
    last_update_time = 0.0
    last_typing_time = 0.0

    try:
        async for raw_line in proc.stdout:
            line = raw_line.decode("utf-8", errors="replace").strip()
            if not line:
                continue

            now = time.time()

            if now - last_typing_time > TYPING_INTERVAL:
                try:
                    await bot.send_chat_action(chat_id, ChatAction.TYPING)
                except Exception:
                    pass
                last_typing_time = now

            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                accumulated_text += line + "\n"
                continue

            etype = event.get("type", "")

            if etype == "assistant":
                msg = event.get("message", {})
                if isinstance(msg, dict):
                    for block in msg.get("content", []):
                        btype = block.get("type", "")
                        if btype == "text":
                            accumulated_text = block.get("text", "")
                        elif btype == "tool_use":
                            tool_name = block.get("name", "unknown")
                            tools_used.append(tool_name)

                if tools_used and now - last_update_time > UPDATE_INTERVAL:
                    last_update_time = now
                    recent = tools_used[-1]
                    status = f"<b>{recent}</b>"
                    if len(tools_used) > 1:
                        status += f"\n<i>{len(tools_used)} tool calls so far</i>"
                    try:
                        await bot.edit_message_text(
                            chat_id=chat_id,
                            message_id=status_msg_id,
                            text=f"Working...\n\n{status}",
                            parse_mode=ParseMode.HTML,
                        )
                    except Exception:
                        pass

            elif etype == "result":
                new_session_id = event.get("session_id", new_session_id)
                if event.get("result"):
                    result_text = event["result"]
                cost = event.get("cost_usd")
                duration = event.get("duration_ms")
                turns = event.get("num_turns")
                if cost is not None:
                    log.info(
                        f"Claude done: cost=${cost:.4f}, "
                        f"duration={duration}ms, turns={turns}"
                    )

        await asyncio.wait_for(proc.wait(), timeout=30)

    except asyncio.CancelledError:
        proc.kill()
        result_text = "Operation cancelled."
    except asyncio.TimeoutError:
        proc.kill()
        result_text = "Operation timed out waiting for process to exit."
    except Exception as e:
        result_text = f"Error during Claude execution: {e}"
        log.exception("Claude bridge error")
    finally:
        session.is_running = False
        session.current_proc = None

    if not result_text and accumulated_text:
        result_text = accumulated_text

    return result_text, new_session_id, tools_used


# =============================================================================
# MCP Internal HTTP API
# =============================================================================
# These endpoints are called by the Telegram MCP server running inside the
# Marvin container. They enable Claude to interact with the Telegram user
# mid-execution (ask questions, send messages, send files).

async def api_health(request: web.Request) -> web.Response:
    """Health check endpoint."""
    return web.json_response({
        "status": "ok",
        "active_chat": active_chat_id,
        "has_pending_question": pending_question is not None,
    })


async def api_ask(request: web.Request) -> web.Response:
    """
    Ask the Telegram user a question and wait for their response.
    Called by the MCP server's telegram_ask tool.
    """
    global pending_question, mcp_choices

    if not active_chat_id:
        return web.json_response(
            {"status": "error", "response": "No active Telegram chat."},
            status=400,
        )

    data = await request.json()
    question = data.get("question", "")
    choices = data.get("choices", [])
    chat_id = active_chat_id
    bot = bot_app.bot

    # Create a future the message handler will resolve
    loop = asyncio.get_event_loop()
    future = loop.create_future()
    pending_question = {
        "future": future,
        "chat_id": chat_id,
        "question": question,
    }

    # Send the question to Telegram with appropriate UI
    if choices:
        mcp_choices = list(choices)
        buttons = []
        for i, choice in enumerate(choices):
            # Truncate label if needed, callback_data max 64 bytes
            label = choice[:60]
            buttons.append(
                [InlineKeyboardButton(label, callback_data=f"mcp:{i}")]
            )
        await bot.send_message(
            chat_id=chat_id,
            text=f"<b>Question from Claude:</b>\n{question}",
            reply_markup=InlineKeyboardMarkup(buttons),
            parse_mode=ParseMode.HTML,
        )
    else:
        # Use ForceReply to auto-open the reply keyboard
        await bot.send_message(
            chat_id=chat_id,
            text=f"<b>Question from Claude:</b>\n{question}",
            reply_markup=ForceReply(selective=False, input_field_placeholder="Your answer..."),
            parse_mode=ParseMode.HTML,
        )

    log.info(f"MCP ask: '{question}' with {len(choices)} choices")

    # Block until the user responds or timeout
    try:
        response = await asyncio.wait_for(future, timeout=ASK_TIMEOUT)
        return web.json_response({"status": "ok", "response": response})
    except asyncio.TimeoutError:
        pending_question = None
        mcp_choices.clear()
        return web.json_response({
            "status": "timeout",
            "response": f"User did not respond within {ASK_TIMEOUT // 60} minutes.",
        })


async def api_send_message(request: web.Request) -> web.Response:
    """
    Send a message to the Telegram user (non-blocking).
    Called by the MCP server's telegram_send_message tool.
    """
    if not active_chat_id:
        return web.json_response({"status": "error"}, status=400)

    data = await request.json()
    text = data.get("text", "")
    bot = bot_app.bot

    await send_telegram(active_chat_id, text, bot)
    log.info(f"MCP send_message to chat {active_chat_id}")
    return web.json_response({"status": "ok"})


async def api_send_file(request: web.Request) -> web.Response:
    """
    Send a file to the Telegram user.
    Called by the MCP server's telegram_send_file tool.
    """
    if not active_chat_id:
        return web.json_response({"status": "error"}, status=400)

    data = await request.json()
    filepath = data.get("path", "")
    caption = data.get("caption", "")
    bot = bot_app.bot

    path = Path(filepath)
    if not path.exists() or not path.is_file():
        return web.json_response(
            {"status": "error", "message": f"File not found: {filepath}"},
            status=404,
        )

    await send_file(active_chat_id, path, bot, caption=caption)
    return web.json_response({"status": "ok"})


# =============================================================================
# Command Handlers
# =============================================================================

@authorized
async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Welcome message and help."""
    user = update.effective_user
    await update.message.reply_text(
        f"<b>Marvin Telegram Interface</b>\n\n"
        f"<i>\"Brain the size of a planet and they have me answering "
        f"Telegram messages...\"</i>\n\n"
        f"Hello {user.first_name}. Send me any message and I'll "
        f"relay it to Marvin's Claude instance.\n\n"
        f"<b>Commands:</b>\n"
        f"/new - Start a fresh Claude session\n"
        f"/status - Session &amp; container info\n"
        f"/files - Browse engagement files\n"
        f"/send &lt;path&gt; - Send a file\n"
        f"/engagements - List engagements\n"
        f"/cancel - Cancel running operation\n"
        f"/id - Show your Telegram user ID\n"
        f"/help - Show this help\n\n"
        f"<b>Rich Input:</b>\n"
        f"Photos, documents, voice, video, location, contacts "
        f"are all forwarded to Claude.\n\n"
        f"<b>MCP Bridge:</b>\n"
        f"Claude can ask you questions mid-task and send files "
        f"directly through the telegram MCP server.",
        parse_mode=ParseMode.HTML,
    )


@authorized
async def cmd_new(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Start a new Claude session."""
    chat_id = update.effective_chat.id
    session = get_session(chat_id)

    if session.is_running:
        await update.message.reply_text(
            "A command is still running. Use /cancel first."
        )
        return

    old_id = session.session_id
    sessions[chat_id] = Session()

    msg = "New session started."
    if old_id:
        msg += f"\n<i>Previous: <code>{old_id[:16]}...</code></i>"
    await update.message.reply_text(msg, parse_mode=ParseMode.HTML)


@authorized
async def cmd_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Show session and container status."""
    chat_id = update.effective_chat.id
    session = get_session(chat_id)

    proc = await asyncio.create_subprocess_exec(
        "docker", "inspect", "--format",
        "{{.State.Status}}|{{.State.Health.Status}}",
        MARVIN_CONTAINER,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, _ = await proc.communicate()
    raw = stdout.decode().strip() if proc.returncode == 0 else "not_found|unknown"
    parts = raw.split("|")
    state = parts[0] if parts else "unknown"
    health = parts[1] if len(parts) > 1 else "unknown"

    state_icon = {"running": "ON", "exited": "OFF"}.get(state, "??")
    health_icon = {"healthy": "OK"}.get(health, "!!")

    text = (
        f"<b>Marvin Status</b>\n\n"
        f"Container: [{state_icon}] <code>{state}</code>\n"
        f"Health: [{health_icon}] <code>{health}</code>\n\n"
        f"<b>Session</b>\n"
        f"ID: <code>{session.session_id or 'none (use /new or send a message)'}</code>\n"
        f"Active: {'yes' if session.is_running else 'no'}\n"
        f"Messages: {session.message_count}\n"
        f"Last active: {session.last_active.strftime('%Y-%m-%d %H:%M:%S')}\n"
    )

    await update.message.reply_text(text, parse_mode=ParseMode.HTML)


@authorized
async def cmd_engagements(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """List engagement directories."""
    eng_path = Path(WORKSPACE_PATH) / "engagements"

    if not eng_path.exists():
        await update.message.reply_text("No engagements directory yet.")
        return

    clients = sorted([d for d in eng_path.iterdir() if d.is_dir()])
    if not clients:
        await update.message.reply_text("No engagements found.")
        return

    text = "<b>Engagements</b>\n\n"
    for client_dir in clients:
        text += f"<b>{client_dir.name}/</b>\n"
        for eng_dir in sorted(client_dir.iterdir()):
            if eng_dir.is_dir():
                file_count = sum(1 for f in eng_dir.rglob("*") if f.is_file())
                text += f"  {eng_dir.name}/ ({file_count} files)\n"
        text += "\n"

    for part in split_message(text):
        await update.message.reply_text(part, parse_mode=ParseMode.HTML)


@authorized
async def cmd_files(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Browse engagement files with inline download buttons."""
    eng_path = Path(WORKSPACE_PATH) / "engagements"

    if not eng_path.exists():
        await update.message.reply_text("No engagements yet.")
        return

    report_files = []
    for f in eng_path.rglob("report/*"):
        if f.is_file() and f.suffix in (".pdf", ".md", ".txt", ".html"):
            report_files.append(f)

    target_files = report_files
    label = "Report Files"

    if not target_files:
        target_files = sorted(
            [f for f in eng_path.rglob("*") if f.is_file()],
            key=lambda p: p.stat().st_mtime,
            reverse=True,
        )[:MAX_FILE_BUTTONS]
        label = "Engagement Files"

    if not target_files:
        await update.message.reply_text("No files found in engagements.")
        return

    ext_icons = {
        ".pdf": "PDF", ".md": "MD", ".txt": "TXT",
        ".html": "HTML", ".csv": "CSV", ".json": "JSON",
        ".png": "IMG", ".jpg": "IMG", ".xml": "XML",
    }

    buttons = []
    for f in sorted(target_files, key=lambda p: p.stat().st_mtime, reverse=True)[
        :MAX_FILE_BUTTONS
    ]:
        rel = f.relative_to(Path(WORKSPACE_PATH))
        ext_label = ext_icons.get(f.suffix, "FILE")
        display = f"[{ext_label}] {rel}"
        key = register_file(str(f))
        buttons.append([InlineKeyboardButton(display, callback_data=key)])

    await update.message.reply_text(
        f"<b>{label}</b>\nTap to download:",
        reply_markup=InlineKeyboardMarkup(buttons),
        parse_mode=ParseMode.HTML,
    )


@authorized
async def cmd_send(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Send a specific file by path."""
    if not context.args:
        await update.message.reply_text(
            "Usage: /send &lt;path&gt;\n"
            "Example: /send engagements/client/osint_2025-01-01/report/report.pdf",
            parse_mode=ParseMode.HTML,
        )
        return

    filepath = " ".join(context.args)
    if not filepath.startswith("/"):
        filepath = os.path.join(WORKSPACE_PATH, filepath)

    path = Path(filepath)
    if not path.exists() or not path.is_file():
        await update.message.reply_text(f"File not found: {filepath}")
        return

    await send_file(update.effective_chat.id, path, context.bot)


@authorized
async def cmd_cancel(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Cancel the currently running operation."""
    global pending_question
    chat_id = update.effective_chat.id
    session = get_session(chat_id)

    if not session.is_running or not session.current_proc:
        await update.message.reply_text("Nothing running to cancel.")
        return

    try:
        session.current_proc.kill()
        session.is_running = False
        session.current_proc = None
        # Also clear any pending MCP question
        if pending_question and not pending_question["future"].done():
            pending_question["future"].set_result("[Cancelled by user]")
        pending_question = None
        mcp_choices.clear()
        await update.message.reply_text("Operation cancelled.")
    except Exception as e:
        await update.message.reply_text(f"Error cancelling: {e}")


async def cmd_id(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Show the user's Telegram ID (no auth required)."""
    user = update.effective_user
    await update.message.reply_text(
        f"Your Telegram user ID: <code>{user.id}</code>\n"
        f"Add this to TELEGRAM_ALLOWED_USERS in .env to authorize.",
        parse_mode=ParseMode.HTML,
    )


@authorized
async def cmd_help(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Show help."""
    await cmd_start(update, context)


# =============================================================================
# Callback Handler
# =============================================================================

async def callback_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle inline keyboard button presses."""
    global pending_question
    query = update.callback_query
    data = query.data

    # MCP choice button (from telegram_ask with choices)
    if data.startswith("mcp:"):
        await query.answer()
        if pending_question and not pending_question["future"].done():
            idx = int(data.split(":")[1])
            choice = mcp_choices[idx] if idx < len(mcp_choices) else f"Option {idx + 1}"
            pending_question["future"].set_result(choice)
            pending_question = None
            mcp_choices.clear()
            # Update the message to show the selected choice
            try:
                await query.message.edit_text(
                    f"{query.message.text}\n\n<i>You selected: {choice}</i>",
                    parse_mode=ParseMode.HTML,
                )
            except Exception:
                pass
        else:
            await query.message.reply_text("This question has already been answered.")
        return

    # File download button
    await query.answer()
    if data in file_registry:
        filepath = file_registry[data]
        path = Path(filepath)
        if path.exists() and path.is_file():
            await send_file(query.message.chat_id, path, context.bot)
        else:
            await query.message.reply_text(f"File no longer exists: {path.name}")


async def send_file(chat_id: int, path: Path, bot, caption: str = ""):
    """Send a file via Telegram."""
    try:
        file_size = path.stat().st_size
        if file_size > 50 * 1024 * 1024:
            await bot.send_message(
                chat_id,
                f"File too large ({file_size // 1024 // 1024}MB). Telegram limit is 50MB.",
            )
            return

        cap = caption or f"{path.name} ({file_size // 1024}KB)"
        with open(path, "rb") as f:
            await bot.send_document(
                chat_id=chat_id,
                document=InputFile(f, filename=path.name),
                caption=cap,
            )
        log.info(f"Sent file: {path.name} to chat {chat_id}")
    except Exception as e:
        await bot.send_message(chat_id, f"Error sending file: {e}")
        log.error(f"Failed to send file {path}: {e}")


# =============================================================================
# Message Handlers
# =============================================================================

@authorized
async def handle_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle plain text messages."""
    global pending_question
    chat_id = update.effective_chat.id

    # If there's a pending MCP question, this message is the answer
    if pending_question and pending_question.get("chat_id") == chat_id:
        future = pending_question["future"]
        if not future.done():
            future.set_result(update.message.text)
        pending_question = None
        mcp_choices.clear()
        return

    session = get_session(chat_id)
    if session.is_running:
        await update.message.reply_text(
            "Still processing the previous message. Wait or /cancel."
        )
        return

    await process_message(chat_id, update.message.text, session, context.bot)


@authorized
async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle photos."""
    chat_id = update.effective_chat.id
    session = get_session(chat_id)

    if session.is_running:
        await update.message.reply_text("Still processing. Wait or /cancel.")
        return

    photo = update.message.photo[-1]
    tg_file = await photo.get_file()

    uploads_dir = Path(WORKSPACE_PATH) / "uploads"
    uploads_dir.mkdir(exist_ok=True)

    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"photo_{ts}_{photo.file_unique_id}.jpg"
    filepath = uploads_dir / filename
    await tg_file.download_to_drive(str(filepath))

    caption = update.message.caption or ""
    message = (
        f"The user sent a photo via Telegram. "
        f"It has been saved to: /workspace/uploads/{filename}\n"
    )
    if caption:
        message += f"Caption: {caption}\n"
    message += "Please analyze or use this image as appropriate."

    await process_message(chat_id, message, session, context.bot)


@authorized
async def handle_document(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle documents."""
    chat_id = update.effective_chat.id
    session = get_session(chat_id)

    if session.is_running:
        await update.message.reply_text("Still processing. Wait or /cancel.")
        return

    doc = update.message.document
    tg_file = await doc.get_file()

    uploads_dir = Path(WORKSPACE_PATH) / "uploads"
    uploads_dir.mkdir(exist_ok=True)

    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    original_name = doc.file_name or "document"
    filename = f"{ts}_{original_name}"
    filepath = uploads_dir / filename
    await tg_file.download_to_drive(str(filepath))

    caption = update.message.caption or ""
    message = (
        f"The user sent a document via Telegram.\n"
        f"File: {original_name}\n"
        f"Type: {doc.mime_type or 'unknown'}\n"
        f"Size: {doc.file_size or 0} bytes\n"
        f"Saved to: /workspace/uploads/{filename}\n"
    )
    if caption:
        message += f"Caption: {caption}\n"
    message += "Please review this file."

    await process_message(chat_id, message, session, context.bot)


@authorized
async def handle_voice(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle voice messages."""
    chat_id = update.effective_chat.id
    session = get_session(chat_id)

    if session.is_running:
        await update.message.reply_text("Still processing. Wait or /cancel.")
        return

    voice = update.message.voice
    tg_file = await voice.get_file()

    uploads_dir = Path(WORKSPACE_PATH) / "uploads"
    uploads_dir.mkdir(exist_ok=True)

    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"voice_{ts}.ogg"
    filepath = uploads_dir / filename
    await tg_file.download_to_drive(str(filepath))

    message = (
        f"The user sent a voice message ({voice.duration}s) via Telegram.\n"
        f"Saved to: /workspace/uploads/{filename}\n"
        f"This is an OGG audio file."
    )

    await process_message(chat_id, message, session, context.bot)


@authorized
async def handle_location(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle shared locations."""
    chat_id = update.effective_chat.id
    session = get_session(chat_id)

    if session.is_running:
        await update.message.reply_text("Still processing. Wait or /cancel.")
        return

    loc = update.message.location
    message = (
        f"The user shared a location via Telegram:\n"
        f"Latitude: {loc.latitude}\n"
        f"Longitude: {loc.longitude}\n"
    )
    if loc.horizontal_accuracy:
        message += f"Accuracy: {loc.horizontal_accuracy}m\n"

    await process_message(chat_id, message, session, context.bot)


@authorized
async def handle_contact(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle shared contacts."""
    chat_id = update.effective_chat.id
    session = get_session(chat_id)

    if session.is_running:
        await update.message.reply_text("Still processing. Wait or /cancel.")
        return

    contact = update.message.contact
    parts = []
    if contact.first_name:
        name = contact.first_name
        if contact.last_name:
            name += f" {contact.last_name}"
        parts.append(f"Name: {name}")
    if contact.phone_number:
        parts.append(f"Phone: {contact.phone_number}")
    if contact.user_id:
        parts.append(f"Telegram ID: {contact.user_id}")

    message = "The user shared a contact via Telegram:\n" + "\n".join(parts)

    await process_message(chat_id, message, session, context.bot)


@authorized
async def handle_video(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle video messages."""
    chat_id = update.effective_chat.id
    session = get_session(chat_id)

    if session.is_running:
        await update.message.reply_text("Still processing. Wait or /cancel.")
        return

    video = update.message.video
    tg_file = await video.get_file()

    uploads_dir = Path(WORKSPACE_PATH) / "uploads"
    uploads_dir.mkdir(exist_ok=True)

    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    ext = Path(video.file_name).suffix if video.file_name else ".mp4"
    filename = f"video_{ts}{ext}"
    filepath = uploads_dir / filename
    await tg_file.download_to_drive(str(filepath))

    caption = update.message.caption or ""
    message = (
        f"The user sent a video via Telegram.\n"
        f"Duration: {video.duration}s\n"
        f"Size: {video.file_size or 0} bytes\n"
        f"Saved to: /workspace/uploads/{filename}\n"
    )
    if caption:
        message += f"Caption: {caption}\n"

    await process_message(chat_id, message, session, context.bot)


# =============================================================================
# Core Message Processing
# =============================================================================

async def process_message(
    chat_id: int,
    message: str,
    session: Session,
    bot,
):
    """Process a user message through Claude and send back the response."""
    global active_chat_id
    active_chat_id = chat_id

    session.last_active = datetime.now()
    session.message_count += 1
    session.files_before = scan_workspace_files()

    status_msg = await bot.send_message(chat_id=chat_id, text="Processing...")

    try:
        await bot.send_chat_action(chat_id, ChatAction.TYPING)
    except Exception:
        pass

    result_text, new_session_id, tools_used = await run_claude(
        message=message,
        session=session,
        chat_id=chat_id,
        bot=bot,
        status_msg_id=status_msg.message_id,
    )

    if new_session_id:
        session.session_id = new_session_id

    try:
        await bot.delete_message(chat_id, status_msg.message_id)
    except Exception:
        pass

    if not result_text:
        result_text = "No response from Claude."

    parts = split_message(result_text)
    for part in parts:
        formatted = format_for_telegram(part)
        try:
            await bot.send_message(
                chat_id=chat_id,
                text=formatted,
                parse_mode=ParseMode.HTML,
            )
        except Exception:
            try:
                await bot.send_message(chat_id=chat_id, text=part)
            except Exception as e:
                log.error(f"Failed to send message part: {e}")

    # Detect new files created during this operation
    files_after = scan_workspace_files()
    new_files = files_after - session.files_before

    if new_files:
        interesting_exts = {
            ".pdf", ".md", ".txt", ".html", ".csv", ".json",
            ".png", ".jpg", ".xml", ".xlsx",
        }
        report_files = [
            f for f in new_files if Path(f).suffix in interesting_exts
        ]

        if report_files:
            ext_labels = {
                ".pdf": "PDF", ".md": "MD", ".txt": "TXT",
                ".html": "HTML", ".csv": "CSV", ".json": "JSON",
                ".png": "IMG", ".jpg": "IMG", ".xml": "XML",
                ".xlsx": "XLS",
            }

            buttons = []
            for f in sorted(report_files)[:MAX_FILE_BUTTONS]:
                path = Path(f)
                ext_label = ext_labels.get(path.suffix, "FILE")
                display = f"[{ext_label}] {path.name}"
                key = register_file(f)
                buttons.append(
                    [InlineKeyboardButton(display, callback_data=key)]
                )

            await bot.send_message(
                chat_id=chat_id,
                text=f"<b>{len(new_files)} new file(s) created.</b> Tap to download:",
                reply_markup=InlineKeyboardMarkup(buttons),
                parse_mode=ParseMode.HTML,
            )


# =============================================================================
# Bot Setup & Main
# =============================================================================

async def post_init(app: Application):
    """Register bot commands with Telegram after startup."""
    commands = [
        BotCommand("new", "Start a fresh Claude session"),
        BotCommand("status", "Session & container info"),
        BotCommand("files", "Browse engagement files"),
        BotCommand("send", "Send a file from workspace"),
        BotCommand("engagements", "List engagements"),
        BotCommand("cancel", "Cancel running operation"),
        BotCommand("id", "Show your Telegram user ID"),
        BotCommand("help", "Show help"),
    ]
    await app.bot.set_my_commands(commands)
    log.info("Bot commands registered with Telegram")


async def main():
    """Start both the Telegram bot and the MCP HTTP API."""
    global bot_app

    log.info("Starting Marvin Telegram Bot...")
    log.info(f"Container target: {MARVIN_CONTAINER}")
    log.info(f"Workspace path: {WORKSPACE_PATH}")
    log.info(f"MCP API port: {MCP_API_PORT}")
    if ALLOWED_USERS:
        log.info(f"Allowed users: {ALLOWED_USERS}")
    else:
        log.warning(
            "TELEGRAM_ALLOWED_USERS not set - bot is open to ALL users. "
            "Set this in .env for security."
        )

    # Build the Telegram application
    app = (
        Application.builder()
        .token(TELEGRAM_BOT_TOKEN)
        .post_init(post_init)
        .build()
    )
    bot_app = app

    # Command handlers
    app.add_handler(CommandHandler("start", cmd_start))
    app.add_handler(CommandHandler("new", cmd_new))
    app.add_handler(CommandHandler("status", cmd_status))
    app.add_handler(CommandHandler("files", cmd_files))
    app.add_handler(CommandHandler("send", cmd_send))
    app.add_handler(CommandHandler("engagements", cmd_engagements))
    app.add_handler(CommandHandler("cancel", cmd_cancel))
    app.add_handler(CommandHandler("id", cmd_id))
    app.add_handler(CommandHandler("help", cmd_help))

    # Callback handler for inline buttons
    app.add_handler(CallbackQueryHandler(callback_handler))

    # Message handlers
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text))
    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))
    app.add_handler(MessageHandler(filters.Document.ALL, handle_document))
    app.add_handler(MessageHandler(filters.VOICE, handle_voice))
    app.add_handler(MessageHandler(filters.LOCATION, handle_location))
    app.add_handler(MessageHandler(filters.CONTACT, handle_contact))
    app.add_handler(MessageHandler(filters.VIDEO, handle_video))

    # Build the MCP HTTP API server
    web_app = web.Application()
    web_app.router.add_get("/api/health", api_health)
    web_app.router.add_post("/api/ask", api_ask)
    web_app.router.add_post("/api/send", api_send_message)
    web_app.router.add_post("/api/file", api_send_file)

    runner = web.AppRunner(web_app)
    await runner.setup()
    site = web.TCPSite(runner, "0.0.0.0", MCP_API_PORT)

    # Start everything
    async with app:
        await app.start()
        await app.updater.start_polling(
            allowed_updates=Update.ALL_TYPES,
            drop_pending_updates=True,
        )
        await site.start()
        log.info(f"MCP HTTP API listening on port {MCP_API_PORT}")
        log.info("Bot is live. Polling for updates...")

        # Run forever
        try:
            await asyncio.Event().wait()
        finally:
            log.info("Shutting down...")
            await app.updater.stop()
            await app.stop()
            await runner.cleanup()


if __name__ == "__main__":
    asyncio.run(main())
