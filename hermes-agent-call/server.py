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


def write_json(handler: BaseHTTPRequestHandler, status: int, payload: dict) -> None:
    raw = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(raw)))
    handler.end_headers()
    handler.wfile.write(raw)


def _is_horizontal_rule(line: str) -> bool:
    """Bottom border of the new Hermes panel (mostly ─ / box-drawing, no text)."""
    t = line.strip()
    if len(t) < 20:
        return False
    if any(c.isalnum() for c in t):
        return False
    if any("\u4e00" <= c <= "\u9fff" for c in t):
        return False
    for c in t:
        if c.isspace():
            continue
        if c in "─－━—‐-‒":
            continue
        o = ord(c)
        if 0x2500 <= o <= 0x257F:
            continue
        return False
    non_space = [c for c in t if not c.isspace()]
    return len(non_space) >= 10


def extract_hermes_reply(stdout: str) -> str:
    """Strip TUI chrome; return text inside the ⚕ Hermes panel (old ╭/╰ or new ─ layout)."""
    lines = (stdout or "").splitlines()
    start = -1
    for i, line in enumerate(lines):
        if "⚕" in line and "Hermes" in line:
            start = i
            break
    if start < 0:
        return (stdout or "").strip()

    content: list[str] = []
    for line in lines[start + 1 :]:
        s = line.strip()
        if s.startswith("╰"):
            break
        if _is_horizontal_rule(line):
            break
        stripped = re.sub(r"^[│\s]+", "", line).strip()
        if not stripped or stripped.startswith("╭"):
            continue
        content.append(stripped)
    text = "\n".join(content).strip()
    return text if text else (stdout or "").strip()


class HermesCallHandler(BaseHTTPRequestHandler):
    def do_POST(self) -> None:
        if self.path != "/call":
            write_json(self, 404, {"ok": False, "error": "not found"})
            return

        content_length = self.headers.get("Content-Length", "0")
        try:
            body_bytes = self.rfile.read(int(content_length))
            data = json.loads(body_bytes.decode("utf-8") if body_bytes else "{}")
        except Exception:
            write_json(self, 400, {"ok": False, "error": "invalid json body"})
            return

        sessionid = str(data.get("sessionid", "")).strip()
        message = str(data.get("message", "")).strip()
        if not message:
            write_json(
                self,
                400,
                {"ok": False, "error": "message is required and must be non-empty"},
            )
            return

        args = [
            NERDCTL_CMD,
            "exec",
            HERMES_AGENT_CONTAINER,
            HERMES_BIN,
            "chat",
            "--yolo",
            "-c",
            "-q",
            message,
        ]

        command_parts = [
            shell_arg_display(NERDCTL_CMD),
            "exec",
            shell_arg_display(HERMES_AGENT_CONTAINER),
            shell_arg_display(HERMES_BIN),
            "chat",
            "--yolo",
            "-c",
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
            write_json(
                self,
                500,
                {
                    "ok": False,
                    "message": message,
                    "command": command_str,
                    "error": f"failed to execute {NERDCTL_CMD}: {err}",
                },
            )
            return

        success = completed.returncode == 0
        write_json(
            self,
            200 if success else 500,
            {
                "ok": success,
                "sessionid": sessionid,
                "message": message,
                "command": command_str,
                "exitCode": completed.returncode,
                "stdout": extract_hermes_reply(completed.stdout or ""),
                "stderr": (completed.stderr or "").strip(),
                **({} if success else {"error": "hermes command failed"}),
            },
        )

    def log_message(self, _format: str, *_args) -> None:
        return


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", PORT), HermesCallHandler)
    server.daemon_threads = True
    print(f"hermes-agent-call listening on http://0.0.0.0:{PORT}")
    server.serve_forever()
