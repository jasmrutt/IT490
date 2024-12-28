#!/usr/bin/env python3

import pika
import os
import json
import mysql.connector
from mysql.connector import pooling
from datetime import datetime
from statistics import correlation

db_config = {
  'user': 'admin',
  'password': os.environ['mdb_passwd'],
  'host': os.environ['mdb_ip'],
  'database': 'applicare',
  'ssl_disabled': True
}

try:
  conn = mysql.connector.connect(**db_config)
  print("Successfully connected to database")
  conn.close()
except mysql.connector.Error as err:
  print(f"Error: {err}")

pool = pooling.MySQLConnectionPool(pool_name="db_pool", pool_size=5, **db_config)

connection = pika.BlockingConnection(pika.ConnectionParameters(os.environ['rmq_ip'], credentials=pika.PlainCredentials('admin', os.environ['rmq_passwd'])))
channel = connection.channel()
channel.exchange_declare(exchange='applicare', exchange_type='direct', durable=True)
channel.queue_declare(queue='database_queue', durable=True, arguments={'x-message-ttl':60_000, 'x-queue-type': 'quorum'})
channel.queue_bind(exchange='applicare', queue='database_queue', routing_key='database')

def listen_for_requests():
  def callback(ch, method, properties, body):
    try:
      request = json.loads(body)
      print(f"Received message: {properties.correlation_id}")
      print(f"Request: {request}")
      execute_query(request, properties.correlation_id)
      ch.basic_ack(delivery_tag=method.delivery_tag)
    except Exception as e:
      print(f"Error processing message: {e}")
      ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
  channel.basic_consume(queue='database_queue', on_message_callback=callback, auto_ack=False)
  print('Waiting for database queries...')
  channel.start_consuming()

def serialize_row(row):
  return [item.isoformat() if isinstance(item, datetime) else item for item in row]

def execute_query(body, correlation_id):
  try:
    db_connection = pool.get_connection()
    cursor = db_connection.cursor()
    cursor.execute(body['query'])
    if cursor.description is None:
      affected_rows = cursor.rowcount
      if affected_rows > 0:
        db_connection.commit()
        print(f"(success) Affected rows: {affected_rows} :: {correlation_id}")
        send_db_response({"status": "success", "affected_rows": affected_rows}, correlation_id)
      else:
        print(f"(error) Affected rows: {affected_rows} :: {correlation_id}")
        send_db_response({"status": "error", "message": "No rows affected."}, correlation_id)
    else:
      results = cursor.fetchall()
      columns = [desc[0] for desc in cursor.description]
      print(f"Query results: {results}")
      serialized_results = [serialize_row(row) for row in results]
      send_db_response({
        "status": "success",
        "results": {
          "columns": columns,
          "data": serialized_results
        }
      }, correlation_id)
  except mysql.connector.Error as err:
    print(f"Error: {err}")
    send_db_response({"error": str(err)}, correlation_id)
  finally:
    cursor.close()
    db_connection.close()

def send_db_response(response, correlation_id):
  message = json.dumps({"body": response})
  try:
    channel.basic_publish(
      exchange='applicare',
      routing_key='frontend',  # Changed from 'backend' to 'frontend'
      body=message,
      properties=pika.BasicProperties(correlation_id=correlation_id)
    )
    print(f"Sent response to frontend: {correlation_id}")
    print(f"Response: {response}")
  except Exception as e:
    print(f"Error sending response: {e}")

listen_for_requests()
