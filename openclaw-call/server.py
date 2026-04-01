import json
import os
import shlex
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer


PORT = int(os.getenv("PORT", "3010"))
NERDCTL_CMD = os.getenv("NERDCTL_CMD", "nerdctl").strip() or "nerdctl"
OPENCLAW_CONTAINER = os.getenv("OPENCLAW_CONTAINER", "openclaw").strip() or "openclaw"


def write_json(handler: BaseHTTPRequestHandler, status: int, payload: dict) -> None:
    raw = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(raw)))
    handler.end_headers()
    handler.wfile.write(raw)


class OpenClawCallHandler(BaseHTTPRequestHandler):
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
            OPENCLAW_CONTAINER,
            "openclaw",
            "agent",
        ]
        if sessionid:
            args.extend(["--session-id", sessionid])
        args.extend(["--message", message])
        command_str = " ".join(shlex.quote(x) for x in args)

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
                "stdout": (completed.stdout or "").strip(),
                "stderr": (completed.stderr or "").strip(),
                **({} if success else {"error": "openclaw command failed"}),
            },
        )

    def log_message(self, _format: str, *_args) -> None:
        # Keep default access logs silent for cleaner output.
        return


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", PORT), OpenClawCallHandler)
    print(f"openclaw-call listening on http://0.0.0.0:{PORT}")
    server.serve_forever()
