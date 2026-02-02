#!/usr/bin/env python3
"""
Telegram MCP Server for Marvin
===============================
Gives Claude tools to interact with the Telegram user during execution:
- telegram_ask: Ask a question and wait for the user's response
- telegram_send_message: Send a status update or notification
- telegram_send_file: Send a file from the workspace

Communicates with the Telegram bot's HTTP API over the Docker network.
The bot exposes an internal API at http://marvin-telegram:8443.

MCP server config (in mcp-servers.json):
{
    "telegram": {
        "command": "uv",
        "args": ["run", "--with", "mcp>=1.0.0", "--with", "httpx>=0.27",
                 "python", "/workspace/.claude/telegram-mcp/server.py"],
        "env": { "TELEGRAM_API_URL": "http://marvin-telegram:8443" }
    }
}
"""

import os
import asyncio
import httpx
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

BOT_API = os.environ.get("TELEGRAM_API_URL", "http://marvin-telegram:8443")

server = Server("telegram")


@server.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="telegram_ask",
            description=(
                "Ask the Telegram user a question and wait for their response. "
                "Use this whenever you need clarification, confirmation, or input "
                "from the user during a task. You can optionally provide a list of "
                "choices which will be shown as tap-able buttons."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "question": {
                        "type": "string",
                        "description": "The question to ask the user",
                    },
                    "choices": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": (
                            "Optional list of choices. If provided, the user "
                            "can tap a button instead of typing. Keep each "
                            "choice under 60 characters."
                        ),
                    },
                },
                "required": ["question"],
            },
        ),
        Tool(
            name="telegram_send_message",
            description=(
                "Send a message to the Telegram user without waiting for a "
                "response. Use for progress updates, status notifications, "
                "or sharing intermediate results."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "text": {
                        "type": "string",
                        "description": "The message text to send",
                    },
                },
                "required": ["text"],
            },
        ),
        Tool(
            name="telegram_send_file",
            description=(
                "Send a file from the workspace to the Telegram user. "
                "Use to deliver reports, evidence screenshots, tool output, "
                "or any other file the user should receive."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": (
                            "Absolute path to the file to send "
                            "(e.g. /workspace/engagements/client/report/report.pdf)"
                        ),
                    },
                    "caption": {
                        "type": "string",
                        "description": "Optional caption for the file",
                    },
                },
                "required": ["path"],
            },
        ),
    ]


@server.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    if name == "telegram_ask":
        return await _tool_ask(arguments)
    elif name == "telegram_send_message":
        return await _tool_send_message(arguments)
    elif name == "telegram_send_file":
        return await _tool_send_file(arguments)
    return [TextContent(type="text", text=f"Unknown tool: {name}")]


async def _tool_ask(arguments: dict) -> list[TextContent]:
    """Ask the user a question via Telegram and wait for their reply."""
    question = arguments["question"]
    choices = arguments.get("choices", [])

    # Long timeout: we're waiting for a human
    async with httpx.AsyncClient(timeout=httpx.Timeout(320.0)) as client:
        try:
            resp = await client.post(
                f"{BOT_API}/api/ask",
                json={"question": question, "choices": choices},
            )
            data = resp.json()
            status = data.get("status", "error")
            response = data.get("response", "No response received.")

            if status == "timeout":
                return [TextContent(
                    type="text",
                    text=f"The user did not respond within the timeout period. "
                         f"You can continue without their input or try asking again.",
                )]

            return [TextContent(type="text", text=response)]

        except httpx.ConnectError:
            return [TextContent(
                type="text",
                text="Cannot reach the Telegram bot. "
                     "Make sure it is running (make bot-up).",
            )]
        except Exception as e:
            return [TextContent(type="text", text=f"Error asking user: {e}")]


async def _tool_send_message(arguments: dict) -> list[TextContent]:
    """Send a message to the Telegram user."""
    text = arguments["text"]

    async with httpx.AsyncClient(timeout=httpx.Timeout(30.0)) as client:
        try:
            resp = await client.post(
                f"{BOT_API}/api/send",
                json={"text": text},
            )
            if resp.status_code == 200:
                return [TextContent(type="text", text="Message sent to Telegram user.")]
            return [TextContent(
                type="text",
                text=f"Failed to send message: HTTP {resp.status_code}",
            )]

        except httpx.ConnectError:
            return [TextContent(
                type="text",
                text="Cannot reach the Telegram bot. "
                     "Make sure it is running (make bot-up).",
            )]
        except Exception as e:
            return [TextContent(type="text", text=f"Error sending message: {e}")]


async def _tool_send_file(arguments: dict) -> list[TextContent]:
    """Send a file to the Telegram user."""
    path = arguments["path"]
    caption = arguments.get("caption", "")

    async with httpx.AsyncClient(timeout=httpx.Timeout(60.0)) as client:
        try:
            resp = await client.post(
                f"{BOT_API}/api/file",
                json={"path": path, "caption": caption},
            )
            data = resp.json()
            if resp.status_code == 200:
                return [TextContent(type="text", text=f"File sent to Telegram user: {path}")]
            return [TextContent(
                type="text",
                text=f"Failed to send file: {data.get('message', resp.status_code)}",
            )]

        except httpx.ConnectError:
            return [TextContent(
                type="text",
                text="Cannot reach the Telegram bot. "
                     "Make sure it is running (make bot-up).",
            )]
        except Exception as e:
            return [TextContent(type="text", text=f"Error sending file: {e}")]


async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            server.create_initialization_options(),
        )


if __name__ == "__main__":
    asyncio.run(main())
