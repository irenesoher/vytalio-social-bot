import functions_framework
import hashlib
import hmac
import json
import os

from google.cloud import pubsub_v1

_publisher = None

def _get_publisher():
    global _publisher
    if _publisher is None:
        _publisher = pubsub_v1.PublisherClient()
    return _publisher

def _verify_signature(body: bytes, signature: str) -> bool:
    secret   = os.environ["META_APP_SECRET"]
    expected = "sha256=" + hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)

@functions_framework.http
def webhook_receiver(request):
    if request.method == "GET":
        mode      = request.args.get("hub.mode")
        token     = request.args.get("hub.verify_token")
        challenge = request.args.get("hub.challenge")
        if mode == "subscribe" and token == os.environ["VERIFY_TOKEN"]:
            return challenge, 200
        return "Forbidden", 403

    if request.method == "POST":
        body      = request.get_data()
        signature = request.headers.get("X-Hub-Signature-256", "")

        if not _verify_signature(body, signature):
            return "Unauthorized", 401

        payload = json.loads(body)
        if not payload:
            return "No payload", 400

        future = _get_publisher().publish(
            os.environ["PUBSUB_TOPIC_ID"],
            json.dumps(payload).encode("utf-8")
        )
        future.result(timeout=4)
        return "EVENT_RECEIVED", 200

    return "Method Not Allowed", 405
