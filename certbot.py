import http.server
import socketserver

PORT = 80

# Update this with your challenge token and expected response.
# These values are usually provided by Certbot during the challenge setup.
CHALLENGE_PATH = '/.well-known/acme-challenge/EXIpgpyr1m4k5YxifEmEH0QyQWOuxoCtyoXKm1GN4AM'
EXPECTED_RESPONSE = 'EXIpgpyr1m4k5YxifEmEH0QyQWOuxoCtyoXKm1GN4AM.VjJLPZuFSmEsUtw8dzozDWxHidUGr75VB5rw3JHh8no'

class ChallengeHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == CHALLENGE_PATH:
            self.send_response(200)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            self.wfile.write(EXPECTED_RESPONSE.encode())
        else:
            self.send_response(404)
            self.end_headers()

# Start the server
with socketserver.TCPServer(("", PORT), ChallengeHandler) as httpd:
    print(f"Serving at port {PORT}")
    httpd.serve_forever()

