<?php
require_once(__DIR__ . '/rabbitmq-proxy.php');

try {
  $db = new RMQClient();
  echo "Appliances List:\n";
  echo "----------------------------------------\n";
  $result = $db->query("SELECT * FROM appliances");
  if ($result === false) {
    echo "Query failed: " . implode(", ", $db->errorInfo()) . "\n";
    exit(1);
  }
  while ($row = $result->fetch()) {
    printf("ID: %-4s | Brand: %-10s | Model: %s\n",
      $row[0],
      $row[2],
      $row[3]
    );
  }
  echo "----------------------------------------\n";
} catch (Exception $exception) {
  echo "FATAL ERROR: " . $exception->getMessage() . "\n";
  exit(1);
}
