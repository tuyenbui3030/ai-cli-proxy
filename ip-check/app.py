import os
import json
import subprocess
import urllib.request
import re
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(os.environ.get('PORT', 8327))
TARGET_CONTAINER = os.environ.get('TARGET_CONTAINER', 'cli-cli-proxy-api')

def get_direct_ip():
    try:
        # Using a reliable IP echo service
        with urllib.request.urlopen('https://api.ipify.org', timeout=5) as response:
            return response.read().decode('utf-8').strip()
    except Exception as e:
        return f"Error: {str(e)}"

def get_service_ip():
    try:
        # Use wget since it is available in the target container (based on healthcheck)
        cmd = ['docker', 'exec', TARGET_CONTAINER, 'wget', '-qO-', 'https://api.ipify.org']
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        if result.returncode != 0:
            return f"Error (code {result.returncode}): {result.stderr}"
        return result.stdout.strip()
    except Exception as e:
        return f"Error: {str(e)}"

def get_proxy_env():
    try:
        cmd = ['docker', 'exec', TARGET_CONTAINER, 'env']
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        env_vars = result.stdout.split('\n')

        proxy_url = None
        for var in env_vars:
            if var.startswith('ALL_PROXY=') or var.startswith('HTTPS_PROXY=') or var.startswith('HTTP_PROXY='):
                proxy_url = var.split('=', 1)[1]
                break

        if not proxy_url:
            return None

        # Mask password if present: scheme://user:pass@host:port
        # Regex to find user:pass@ and replace pass with ***
        masked = re.sub(r'(://[^:]+):([^@]+)@', r'\1:***@', proxy_url)
        return masked
    except Exception as e:
        return f"Error reading env: {str(e)}"

class IPCheckHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/ip':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()

            ip_direct = get_direct_ip()
            ip_service = get_service_ip()
            proxy_env = get_proxy_env()

            # Logic: If IPs are different and both valid (simple check), proxy is likely working
            # Note: If no proxy is set, IPs should be the same (assuming same NAT)
            # If proxy is set, IPs should be different.

            # Simple validation that we got IP-looking strings
            is_ip = lambda s: len(s.split('.')) == 4 and s.replace('.','').isdigit()

            proxy_working = False
            if is_ip(ip_direct) and is_ip(ip_service):
                if ip_direct != ip_service:
                    proxy_working = True

            response = {
                "ip_direct": ip_direct,
                "ip_service": ip_service,
                "proxy_env": proxy_env,
                "proxy_working": proxy_working,
                "status": "ok"
            }

            self.wfile.write(json.dumps(response).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

def run():
    print(f"Starting IP Check service on port {PORT}...")
    print(f"Target container: {TARGET_CONTAINER}")
    server_address = ('', PORT)
    httpd = HTTPServer(server_address, IPCheckHandler)
    httpd.serve_forever()

if __name__ == '__main__':
    run()
