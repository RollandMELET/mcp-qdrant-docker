from http.server import HTTPServer, BaseHTTPRequestHandler
import time
import sys
import os

class SimpleHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(b'OK')
        print(f"Health check received on path: {self.path}")

    def log_message(self, format, *args):
        # Silence log messages
        return

if __name__ == "__main__":
    try:
        print(f"Starting mock server on port 8000...")
        server = HTTPServer(('0.0.0.0', 8000), SimpleHandler)
        print(f"Mock server started successfully!")
        server.serve_forever()
    except Exception as e:
        print(f"Error starting server: {e}")
        sys.exit(1)
