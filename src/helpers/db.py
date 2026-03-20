import os
import pymysql

def db_init():
    return os.environ['DB_HOST'], os.environ['DB_USER'], os.environ['DB_PASS'], os.environ['DB_NAME'], int(os.environ['DB_PORT'])

def db_create_connection():
    rds_host, name, password, db_name, port = db_init()
    conn = None
    try:
        conn = pymysql.connect(host=rds_host, user=name, passwd=password, db=db_name, port=port, connect_timeout=10)
        conn.autocommit(True)
    except Exception as e:
        print('ERR: Failed to connect to Database:', e)
    return conn

def db_close_connection(conn):
    conn.close()

def rds_query_single(conn, query):
    conn.ping(reconnect=True)
    try:
        with conn.cursor() as cur:
            cur.execute(query)
            for row in cur:
                return [True]+list(row)
    except Exception as e:
        if not conn.open:
            print(f"ERR: exception in query execution '{e}'")
    return [False]

def rds_query(conn, query):
    conn.ping(reconnect=True)
    ret = []
    try:
        with conn.cursor() as cur:
            cur.execute(query)
            for row in cur:
                ret.append(row)
    except Exception as e:
        if not conn.open:
            print(f"ERR: exception in query execution '{e}'")
    return ret

def rds_execute(conn, query, params=None):
    conn.ping(reconnect=True)
    try:
        with conn.cursor() as cur:
            cur.execute(query, params)
            last_id = cur.lastrowid
        conn.commit()
        return [True, last_id]
    except Exception as e:
        conn.rollback()
        print(f"ERR: query execution failed: {e}")
        return [False, None]

def rds_execute_transactional(conn, query, params=None):
    conn.ping(reconnect=True)
    with conn.cursor() as cur:
        cur.execute(query, params)
        last_id = cur.lastrowid
    return [True, last_id]
