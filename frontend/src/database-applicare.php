<?php
require_once(__DIR__ . '/rabbitmq-proxy.php');

try {
    // Create RMQClient instance for database operations
    $db = new RMQClient();
} catch (Exception $exception) {
    // If there is an error connecting, capture the error message
    $error_message = $exception->getMessage();

        // Display the error message on failure
        echo "<p>Database Error</p>";
        echo "<p>There was an error connecting to RabbitMQ.</p>";
        echo "<p>Error Message: $error_message</p>";

    exit();
}