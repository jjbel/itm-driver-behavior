from flask import Flask, redirect

# serve any file in current directory
app = Flask(__name__, static_url_path="", static_folder="./")

# send root to index.html
@app.route("/")
def index():
    return redirect("/index.html")


# make server publicly available
# https://stackoverflow.com/a/7027113/17100530
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, ssl_context="adhoc")

# use adhoc self-signed certificate for HTTPS
# https://blog.miguelgrinberg.com/post/running-your-flask-application-over-https
# https is needed for camera access:
# see https://p5js.org/reference/p5/createCapture/ and
# https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia
