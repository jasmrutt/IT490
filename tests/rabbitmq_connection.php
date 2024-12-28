<?php

// Include the necessary files for publisher and consumer
include('../src/rabbitmq-publisher.php');  // send messages
include('../src/rabbitmq-consumer.php');   // receive and verify messages

// Can use the AMQPStreamConnection class
use PhpAmqpLib\Connection\AMQPStreamConnection;

// Basic function to test the RabbitMQ connection
function testRabbitMQConnection() {
    try {
        // Try to create a connection to RabbitMQ (from the publisher script)
        $connection = new AMQPStreamConnection('10.0.0.11', 5672, 'guest', 'guest');
        $channel = $connection->channel();
        $channel->queue_declare('userQueue', false, true, false, false);

        echo "RabbitMQ connection is successful!\n";

        // Clean up and close the connection after the test
        $channel->close();
        $connection->close();
    } catch (Exception $e) {
        echo "Error connecting to RabbitMQ: " . $e->getMessage() . "\n";
    }
}

// Call the function to test the RabbitMQ connection
testRabbitMQConnection();

// Optionally, you can test by sending and receiving a message
echo "Publishing test message...\n";
include('../src/rabbitmq-publisher.php'); // Publish a message to the queue

// Allow the consumer to process the message
echo "Waiting for consumer to process the message...\n";
include('../src/rabbitmq-consumer.php'); // Consumer will process the message
?>
