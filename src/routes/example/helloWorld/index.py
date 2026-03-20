"""TYPE: GET"""

from src.helpers.db import *
from src.helpers.misc import *
from src.helpers.queries import *

def hello_world(db_conn, event):
    return {'code': 200, 'message': 'Hello World'}

def handler(event, context):
    db_conn = db_create_connection()
    event = event_handler(event)
    ret = hello_world(db_conn, event)
    db_close_connection(db_conn)
    return ret
