#!/usr/bin/env python3
# Prints the requests from HTTP methods GET, POST, PUT, and DELETE

from http.server import HTTPServer, BaseHTTPRequestHandler
from optparse import OptionParser
import requests
from getmac import get_mac_address as gma


class RequestHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        request_path = self.path

        print("\n----- Request Start ----->\n")
        print("Request path:", request_path)
        print("Request headers:", self.headers)
        print("<----- Request End -----\n")

        self.send_response(200)
        self.end_headers()

    def do_POST(self):
        request_path = self.path

        print("\n----- Request Start ----->\n")
        print("Request path:", request_path)

        request_headers = self.headers
        content_length = request_headers.get('Content-Length')
        length = int(content_length) if content_length else 0

        print("Content Length:", length)
        print("Request headers:", request_headers)
        print("Request payload:", self.rfile.read(length))
        print("<----- Request End -----\n")

        post_result()

        self.send_response(200)
        self.end_headers()

    do_PUT = do_POST
    do_DELETE = do_GET


def post_result():
    url = 'http://localhost:9000/api/v1/monitor/reports'
    mac = gma()
    obj = {'device_id': mac, 'payload': {'type': 'httpprint'}}
    headers = {'Content-Type': 'application/json',
               'Accept': 'application/json'}

    x = requests.post(url, json=obj, headers=headers)

    print("Response:", x.text)

def main():
    port = 5005
    print('Listening on 0.0.0.0:%s' % port)
    server = HTTPServer(('', port), RequestHandler)
    server.serve_forever()


if __name__ == "__main__":
    parser = OptionParser()
    parser.usage = ("Creates an http-server that will print out any GET or POST parameters\n"
                    "Run:\n\n"
                    "   reflect")
    (options, args) = parser.parse_args()

    main()
