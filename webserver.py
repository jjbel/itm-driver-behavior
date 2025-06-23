from flask import Flask, redirect, request, current_app
from pathlib import Path
import socket
from struct import unpack as struct_unpack
from time import time

# disable flask messages
from logging import getLogger

getLogger("werkzeug").disabled = True

udp_ip = "127.0.0.1"
udp_port = 5014

# Create UDP socket for sending
send_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# serve any file in current directory
app = Flask(__name__, static_url_path="", static_folder="./app/")

times = []

START = time()
request_timestamp = time()


@app.before_request
def before_request():
    global request_timestamp
    request_timestamp = time()


# send root to index.html
@app.route("/")
def index():
    return redirect("/index.html")


@app.post("/data")
def saver_data():
    print_request_info()
    send_socket.sendto(request.get_data(), (udp_ip, udp_port))

    return "Data received", 200


def print_request_info():
    data = request.get_data()
    js_time = struct_unpack('d', data[0:8])[0] / 1000
    print(
        f"{request_timestamp - START:.3f} {js_time - START:.3f} {request_timestamp - struct_unpack('d', data[0:8])[0] / 1000:.3f}"
    )
    times.append(js_time)

    if len(times) > 1:
        print(times[-1] - times[-2])


# host="0.0.0.0" : make server publicly available
# https://stackoverflow.com/a/7027113/17100530

# use adhoc self-signed certificate for HTTPS
# https://blog.miguelgrinberg.com/post/running-your-flask-application-over-https
# https is needed for camera access:
# see https://p5js.org/reference/p5/createCapture/ and
# https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, ssl_context="adhoc")

send_socket.close()
