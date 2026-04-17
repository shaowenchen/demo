import json
import os
import re
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


PORT = int(os.getenv("PORT", "3011"))
NERDCTL_CMD = os.getenv("NERDCTL_CMD", "nerdctl").strip() or "nerdctl"
HERMES_AGENT_CONTAINER = os.getenv("HERMES_AGENT_CONTAINER", "hermes-agent").strip() or "hermes-agent"
HERMES_BIN = os.getenv("HERMES_BIN", "/opt/hermes/.venv/bin/hermes").strip() or "/opt/hermes/.venv/bin/hermes"


def shell_double_quoted(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def shell_arg_display(s: str) -> str:
    if any(c in s for c in ' \t\n"$`\\'):
        return shell_double_quoted(s)
    return s


def write_text(handler: BaseHTTPRequestHandler, status: int, body: str) -> None:
    raw = body.encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "text/plain; charset=utf-8")
    handler.send_header("Content-Length", str(len(raw)))
    handler.end_headers()
    handler.wfile.write(raw)


def extract_hermes_reply(stdout: str) -> str:
    """Strip TUI chrome and return the assistant message inside the ⚕ Hermes panel."""
    lines = (stdout or "").splitlines()
    in_panel = False
    content: list[str] = []
    for line in lines:
        if not in_panel:
            if "⚕" in line and "Hermes" in line and "╭" in line:
                in_panel = True
            continue
        if line.strip().startswith("╰"):
            break
        if "╭" in line and content:
            break
        stripped = re.sub(r"^[│\s]+", "", line).strip()
        if stripped and not stripped.startswith("╭"):
            content.append(stripped)
    text = "\n".join(content).strip()
    return text if text else (stdout or "").strip()


class HermesCallHandler(BaseHTTPRequestHandler):
    def do_POST(self) -> None:
        if self.path != "/call":
            write_text(self, 404, "not found")
            return

        content_length = self.headers.get("Content-Length", "0")
        try:
            body_bytes = self.rfile.read(int(content_length))
            data = json.loads(body_bytes.decode("utf-8") if body_bytes else "{}")
        except Exception:
            write_text(self, 400, "invalid json body")
            return

        message = str(data.get("message", "")).strip()
        if not message:
            write_text(self, 400, "message is required and must be non-empty")
            return

        args = [
            NERDCTL_CMD,
            "exec",
            HERMES_AGENT_CONTAINER,
            HERMES_BIN,
            "chat",
            "-q",
            message,
        ]

        command_parts = [
            shell_arg_display(NERDCTL_CMD),
            "exec",
            shell_arg_display(HERMES_AGENT_CONTAINER),
            shell_arg_display(HERMES_BIN),
            "chat",
            "-q",
            shell_double_quoted(message),
        ]
        command_str = " ".join(command_parts)

        try:
            completed = subprocess.run(
                args,
                capture_output=True,
                text=True,
                timeout=3600,
                check=False,
            )
        except Exception as err:
            write_text(
                self,
                500,
                f"failed to execute {NERDCTL_CMD}: {err}\n{command_str}",
            )
            return

        if completed.returncode != 0:
            err_tail = (completed.stderr or completed.stdout or "").strip()
            write_text(
                self,
                500,
                err_tail or f"hermes exited with {completed.returncode}\n{command_str}",
            )
            return

        reply = extract_hermes_reply(completed.stdout or "")
        write_text(self, 200, reply)

    def log_message(self, _format: str, *_args) -> None:
        return


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", PORT), HermesCallHandler)
    server.daemon_threads = True
    print(f"hermes-agent-call listening on http://0.0.0.0:{PORT}")
    server.serve_forever()
