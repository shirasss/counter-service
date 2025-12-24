from flask import Flask, jsonify, Response, request
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
import os
import logging

app = Flask(__name__)

# Logging setup
logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')

# Persistence
DATA_DIR = "/data"
COUNTER_FILE = f"{DATA_DIR}/counter.txt"
VERSION = os.getenv("VERSION", "v1")

def read_counter():
    try:
        with open(COUNTER_FILE, "r") as f:
            return int(f.read())
    except Exception:
        return 0

def write_counter(value):
    with open(COUNTER_FILE, "w") as f:
        f.write(str(value))

# Prometheus metrics
POST_COUNTER = Counter('counter_post_requests_total', 'Total POST requests to increment the counter')
GET_COUNTER = Counter('counter_get_requests_total', 'Total GET requests to read the counter')

# Routes
@app.route("/", methods=["GET"])
def get_counter():
    value = read_counter()
    GET_COUNTER.inc()
    logging.info(f"Counter read: {value}")
    return jsonify({"counter": value, "version": VERSION})

@app.route("/", methods=["POST"])
def increment_counter():
    value = read_counter() + 1
    write_counter(value)
    POST_COUNTER.inc()
    logging.info(f"Counter incremented: {value}")
    return jsonify({"counter": value})

@app.route("/healthz", methods=["GET"])
def health():
    return "ok", 200

@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
