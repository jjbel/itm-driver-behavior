from flask import Flask, redirect, request
from pathlib import Path
import socket

from logging import getLogger
getLogger('werkzeug').disabled = True

target_ip="127.0.0.1"
target_port=5014

# Create UDP socket for sending
send_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# serve any file in current directory
app = Flask(__name__, static_url_path="", static_folder="./")

data = bytes()
file = Path("data.csv")

# send root to index.html
@app.route("/")
def index():
    return redirect("/index.html")

@app.post("/data")
def saver_data():
    global data;
    received = request.get_data()
    print(received)
    data += received
    file.write_bytes(data)
    send_socket.sendto(data, (target_ip, target_port))


    return "Data received", 200

# make server publicly available
# https://stackoverflow.com/a/7027113/17100530

# use adhoc self-signed certificate for HTTPS
# https://blog.miguelgrinberg.com/post/running-your-flask-application-over-https
# https is needed for camera access:
# see https://p5js.org/reference/p5/createCapture/ and
# https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, ssl_context="adhoc")


send_socket.close()
