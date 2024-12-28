#!/usr/bin/env python3

import aio_pika
import json
import asyncio
import os

async def handle_fe_request(body, correlation_id):
  print(f"Processing frontend request: {correlation_id}")
  if "query" in body:
    await send_message("DB", body, correlation_id)
  else:
    processed_response = json.dumps({"message": "sent successfully"})
    await send_message("FE", processed_response, correlation_id)

async def handle_db_response(body, correlation_id):
  print(f"Processing database response: {correlation_id}")
  # processed_response = json.dumps({'message': 'Processed database response successfully', 'body': body})
  await send_message("FE", body, correlation_id)

async def send_message(destination, body, correlation_id):
  message = json.dumps(body)
  connection = await aio_pika.connect(
    f"amqp://admin:{os.environ['rmq_passwd']}@{os.environ['rmq_ip']}/"
  )
  async with connection:
    async with connection.channel() as channel:
      exchange = await channel.declare_exchange(
        name='applicare',
        type=aio_pika.ExchangeType.DIRECT,
        durable=True
      )
      await exchange.publish(
        aio_pika.Message(
          body=message.encode(),
          correlation_id=correlation_id,
        ),
        routing_key=destination.lower()  # 'frontend' or 'database'
      )

async def listen_for_messages():
  connection = await aio_pika.connect(
    f"amqp://admin:{os.environ['rmq_passwd']}@{os.environ['rmq_ip']}/"
  )
  async with connection:
    async with connection.channel() as channel:
      await channel.set_qos(prefetch_count=1)

      exchange = await channel.declare_exchange(
        name='applicare',
        type=aio_pika.ExchangeType.DIRECT,
        durable=True
      )
      backend_queue = await channel.declare_queue(
        'backend_queue',
        durable=True,
        arguments={'x-message-ttl': 60_000, 'x-queue-type': 'quorum'},
      )
      await backend_queue.bind(exchange, routing_key='backend')

      async def callback(message: aio_pika.IncomingMessage):
        try:
          async with message.process():
            msg = json.loads(message.body)
            print(f"Received request: {message.correlation_id}")
            if "query" in msg:
              await handle_fe_request(msg, message.correlation_id)
            else:
              await handle_db_response(msg, message.correlation_id)
            await message.ack()
        except Exception as e:
          print(f"Error with incoming message: {e}")
          await message.nack(requeue=True)

      await backend_queue.consume(callback, no_ack=False)
      print("Waiting for messages...")
      await asyncio.Future()

async def main():
  await listen_for_messages()

if __name__ == "__main__":
  asyncio.run(main())