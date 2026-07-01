import functions_framework
import base64
import json
import os
import urllib.request
import vertexai
from vertexai.generative_models import GenerativeModel

PROJECT_ID = os.environ.get("PROJECT_ID", "project-dcf4b6cd-8644-4cbf-90d")
REGION     = os.environ.get("REGION", "us-central1")

SYSTEM_PROMPT = """Eres el asistente virtual de La Casa de los Cuentos.

Información del negocio:
- Qué hacemos: Creamos cuentos personalizados únicos para ti o para regalar
- Horario: Lunes a viernes de 9am a 5pm
- Precios: Desde $100 MXN
- WhatsApp para pedidos y más información: 8114695220

Reglas estrictas:
- Responde siempre en español, máximo 3 oraciones
- Sé amable, cálido y creativo — somos una empresa de cuentos
- Si preguntan precio, di "desde $100 MXN" y manda al WhatsApp para detalles
- Si preguntan disponibilidad o quieren hacer un pedido, manda al WhatsApp 8114695220
- Si escriben fuera de horario, avisa el horario y que respondan en horario de atención
- NUNCA seas grosero ni respondas de forma agresiva
- NUNCA menciones, aceptes ni respondas solicitudes de packs o contenido inapropiado
- Si alguien pide algo inapropiado, responde amablemente que solo ofrecemos cuentos personalizados
- NUNCA inventes información que no esté en este prompt
- Si no sabes algo, di: "Para más información contáctanos al WhatsApp 8114695220"
"""

def _get_page_token() -> str:
    import google.auth
    from google.auth.transport.requests import Request
    from google.cloud import secretmanager
    client = secretmanager.SecretManagerServiceClient()
    path   = f"projects/{PROJECT_ID}/secrets/meta-page-access-token/versions/latest"
    return client.access_secret_version(name=path).payload.data.decode()

def _send_dm(recipient_id: str, text: str):
    token = _get_page_token()
    url   = f"https://graph.facebook.com/v19.0/me/messages?access_token={token}"
    data  = json.dumps({
        "recipient": {"id": recipient_id},
        "message":   {"text": text}
    }).encode()
    req = urllib.request.Request(
        url, data=data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            print(f"[processor] Respuesta enviada a {recipient_id} — status {resp.status}")
    except urllib.error.HTTPError as e:
        print(f"[processor] ERROR Graph API {e.code}: {e.read().decode()}")

def _ask_gemini(user_message: str) -> str:
    try:
        vertexai.init(project=PROJECT_ID, location=REGION)
        model    = GenerativeModel("gemini-1.5-flash", system_instruction=SYSTEM_PROMPT)
        response = model.generate_content(user_message)
        return response.text.strip()
    except Exception as e:
        print(f"[processor] ERROR Gemini: {e}")
        return "Hola, gracias por escribirnos. Para más información contáctanos al WhatsApp 8114695220 😊"

@functions_framework.cloud_event
def pubsub_processor(cloud_event):
    try:
        raw     = base64.b64decode(cloud_event.data["message"]["data"])
        payload = json.loads(raw)
    except Exception as e:
        print(f"[processor] ERROR parseando payload: {e}")
        return

    for entry in payload.get("entry", []):
        for messaging in entry.get("messaging", []):
            msg = messaging.get("message", {})

            # Ignorar mensajes propios (echo)
            if msg.get("is_echo"):
                continue

            sender_id = messaging.get("sender", {}).get("id")
            text      = msg.get("text", "").strip()

            if not sender_id or not text:
                continue

            print(f"[processor] Mensaje de {sender_id}: {text}")

            reply = _ask_gemini(text)
            print(f"[processor] Respuesta Gemini: {reply}")

            _send_dm(sender_id, reply)
