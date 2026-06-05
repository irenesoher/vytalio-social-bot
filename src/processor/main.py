import functions_framework

@functions_framework.cloud_event
def pubsub_processor(cloud_event):
    print(f"Mensaje recibido de Pub/Sub: {cloud_event.data}")
