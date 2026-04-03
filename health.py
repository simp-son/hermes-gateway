"""Minimal HTTP health server so Render treats this as a Web Service,
enabling persistent disk support for ~/.hermes/"""
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler

class Health(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")
    def log_message(self, *args):
        pass  # suppress access logs

def start():
    server = HTTPServer(("0.0.0.0", 8080), Health)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()

if __name__ == "__main__":
    start()
    print("Health server running on :8080")
    import time
    while True:
        time.sleep(60)
