import json
import requests

def event_handler(event):
    try:
        event_obj = json.loads(event['body'])
        if event.get('headers') and event['headers'].get('secret'):
            event_obj['secret'] = event['headers']['secret']
    except Exception as e:
        return {"code": 500, "message": "content is not proper json!"}
    return event_obj

def send_push_notification(target_token, title, message, extra_data=None):
    if not target_token:
        return

    url = "https://exp.host/--/api/v2/push/send"

    payload = {
        "to": target_token,
        "title": title,
        "body": message,
        "sound": "default",
        "data": extra_data if extra_data else {}
    }

    try:
        response = requests.post(url, json=payload)
        return response.json()
    except Exception as e:
        print(f"Failed to send push: {e}")
        return None
