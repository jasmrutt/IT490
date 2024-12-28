<?php

if (!extension_loaded('amqp')) {
  die("AMQP extension is not loaded. Please install php-amqp package.\n");
}

if (defined('RABBITMQ_PROXY_INCLUDED')) return;
define('RABBITMQ_PROXY_INCLUDED', true);

class RMQClient {
  private $connection;
  private $channel;
  private $exchange;
  private $frontend_queue;
  private $last_error;

  public function __construct($config = null) {
    if ($config === null) {
      // $env = parse_ini_file(__DIR__ . '/.env');
      $config = [
        'host' => '10.0.0.11',
        'port' => 5672,
        'login' => 'admin',
        'password' => 'student123' // $env['rmq_passwd']
      ];
    }
    $this->connect($config);
    register_shutdown_function([$this, 'close']);
  }

  private function connect($config) {
    try {
      $this->connection = new AMQPConnection($config);
      $this->connection->connect();
      $this->channel = new AMQPChannel($this->connection);
      $this->channel->setPrefetchCount(1);
      $this->exchange = new AMQPExchange($this->channel);
      $this->exchange->setName('applicare');
      $this->exchange->setType(AMQP_EX_TYPE_DIRECT);
      $this->exchange->setFlags(AMQP_DURABLE);
      $this->exchange->declareExchange();
      $this->frontend_queue = new AMQPQueue($this->channel);
      $this->frontend_queue->setName('frontend_queue');
      $this->frontend_queue->setFlags(AMQP_DURABLE);
      $this->frontend_queue->setArguments([
        'x-queue-type' => 'quorum',
        'x-message-ttl' => 60000
      ]);
      $this->frontend_queue->declareQueue();
      $this->frontend_queue->bind('applicare', 'frontend');
    } catch (AMQPException $e) {
      $this->last_error = $e->getMessage();
      throw new Exception("RabbitMQ connection error: " . $e->getMessage());
    }
  }

  public function query($sql) {
    try {
      $result = $this->queryDatabase($sql);
      // error_log("Query result from database: " . print_r($result, true));
      if (isset($result['error'])) {
        $this->last_error = $result['error'];
        error_log("Query error: " . $result['error']);
        return false;
      }
      if (isset($result['status']) && $result['status'] === 'error') {
        $this->last_error = isset($result['message']) ? $result['message'] : 'Unknown error';
        return false;
      }
      if (isset($result['results'])) {
        // error_log("Creating RMQResult with data: " . print_r($result['results'], true));
        return new RMQResult($result['results']);
      } else if (isset($result['affected_rows'])) {
        return new RMQResult([]);
      } else {
        error_log("No results found, creating empty RMQResult");
        return new RMQResult([]);
      }
    } catch (Exception $e) {
      $this->last_error = $e->getMessage();
      error_log("Error in query method: " . $e->getMessage());
      return false;
    }
  }

  public function exec($sql) {
    try {
      $result = $this->queryDatabase($sql);
      if (isset($result['status']) && $result['status'] === 'error') {
        $this->last_error = $result['message'];
        return false;
      }      
      return isset($result['affected_rows']) ? $result['affected_rows'] : 0;
    } catch (Exception $e) {
      $this->last_error = $e->getMessage();
      return false;
    }
  }

  public function prepare($sql) { return new RMQStatement($this, $sql); }

  public function errorInfo() { return [$this->last_error]; }

  public function sendRequest($body, $destination = 'backend') {
    try {
      $correlation_id = $this->getUniqueId();
      $message_body = is_string($body) ? $body : json_encode($body);
      // $reply_to = $this->frontend_queue->getName();
      $this->exchange->publish(
        $message_body,
        $destination,
        AMQP_NOPARAM,
        [
          'correlation_id' => $correlation_id,
          // 'reply_to' => $reply_to,
          'delivery_mode' => 2
        ]
      );
      error_log("Published message with correlation_id: $correlation_id to $destination");
      return $correlation_id;
    } catch (Exception $e) {
      $this->last_error = $e->getMessage();
      throw $e;
    }
  }

  public function waitForResponse($correlation_id, $timeout = 30) {
    $start = time();
    $response = null;
    $processed_messages = [];
    while ($response === null && (time() - $start) < $timeout) {
      try {
        while ($message = $this->frontend_queue->get()) {
          $msg_correlation_id = $message->getCorrelationId();
          error_log("Received message with correlation_id: " . $msg_correlation_id);
          // error_log("Message body: " . $message->getBody());
          if ($msg_correlation_id !== $correlation_id) {
            if (!in_array($msg_correlation_id, $processed_messages)) {
              $processed_messages[] = $msg_correlation_id;
              $this->frontend_queue->nack($message->getDeliveryTag(), AMQP_REQUEUE);
            }
            continue;
          }
          $wrapped_response = json_decode($message->getBody(), true);
          // error_log("Parsed response: " . print_r($wrapped_response, true));
          $response = isset($wrapped_response['body']) ? $wrapped_response['body'] : $wrapped_response;
          $this->frontend_queue->ack($message->getDeliveryTag());
          break;
        }
        if ($response === null) {
          usleep(100000);
        }
      } catch (Exception $e) {
        error_log("Error in consume: " . $e->getMessage());
      }
    }
    if ($response === null) {
      $this->last_error = "Request timeout";
      error_log("Timeout waiting for response to correlation_id: $correlation_id");
    }
    return $response;
  }

  private function getUniqueId() {
    return uniqid() . bin2hex(random_bytes(8));
  }

  public function close() {
    if ($this->channel) {
      $this->channel = null;
    }
    if ($this->connection) {
      $this->connection->disconnect();
    }
  }

  private function queryDatabase($query) {
    $message = ['query' => $query];
    $correlation_id = $this->sendRequest($message, 'database');
    $result = $this->waitForResponse($correlation_id);
    if ($result && isset($result['results'])) {
      $columns = $result['results']['columns'];
      $data = $result['results']['data'];
      error_log("Query: " . $query);
      if (empty($data)) {
        error_log("No results found");
      } else {
        foreach ($data as $row) {
          $formatted_values = [];
          foreach ($columns as $i => $column) {
            $formatted_values[] = $column . ": " . $row[$i];
          }
          error_log(implode(" | ", $formatted_values));
        }
        error_log("Total rows: " . count($data));
      }
    } elseif ($result && isset($result['affected_rows'])) {
      error_log("Query: " . $query);
      error_log("Affected rows: " . $result['affected_rows']);
    }
    return $result;
  }

  public function sendToBackend($data) {
    $correlation_id = $this->sendRequest($data, 'backend');
    return $this->waitForResponse($correlation_id);
  }
}

class RMQResult implements Iterator {
  private $results;
  private $position = 0;
  private $fetchStyle = PDO::FETCH_BOTH;
  private $columnNames = [];

  public function __construct($results = []) {
    if (isset($results['data']) && isset($results['columns'])) {
      $this->results = $results['data'];
      $this->columnNames = $results['columns'];
    } else {
      $this->results = is_array($results) ? $results : [];
      $this->columnNames = [];
    }
  }

  public function fetch($fetch_style = null) {
    if ($fetch_style !== null) {
      $this->fetchStyle = $fetch_style;
    }
    if ($this->position >= count($this->results)) {
      return false;
    }
    $row = $this->results[$this->position];
    $this->position++;
    switch ($this->fetchStyle) {
      case PDO::FETCH_ASSOC:
        if (empty($this->columnNames)) {
          return array_combine(range(0, count($row) - 1), $row);
        }
        return array_combine($this->columnNames, $row);
      case PDO::FETCH_NUM:
        return array_values($row);
      case PDO::FETCH_BOTH:
      default:
        $numeric = array_values($row);
        if (empty($this->columnNames)) {
          $assoc = array_combine(range(0, count($row) - 1), $row);
        } else {
          $assoc = array_combine($this->columnNames, $row);
        }
        return array_merge($numeric, $assoc);
    }
  }

  public function fetchColumn($column_number = 0) {
    if ($this->position >= count($this->results)) {
      return false;
    }
    $row = $this->results[$this->position];
    $this->position++;
    if (is_array($row)) {
      if (isset($row[$column_number])) {
        return $row[$column_number];
      }
      if ($column_number >= count($row)) {
        return false;
      }
      $values = array_values($row);
      return $values[$column_number];
    }
    return $column_number === 0 ? $row : false;
  }

  public function fetchAll($fetch_style = null) {
    if ($fetch_style === null) {
      $fetch_style = $this->fetchStyle;
    }
    $rows = [];
    while ($row = $this->fetch($fetch_style)) {
      $rows[] = $row;
    }
    return $rows;
  }

  public function rewind() { $this->position = 0; }
  public function current() { return $this->results[$this->position]; }
  public function key() { return $this->position; }
  public function next() { ++$this->position; }
  public function valid() { return isset($this->results[$this->position]); }
}

class RMQStatement {
  private $rmq;
  private $sql;
  private $params = [];
  private $result = null;

  public function __construct($rmq, $sql) {
    $this->rmq = $rmq;
    $this->sql = $sql;
  }

  public function bindValue($param, $value) {
    $this->params[$param] = $value;
    return true;
  }

  public function bindParam($param, &$var) {
    $this->params[$param] = $var;
    return true;
  }

  public function execute($params = null) {
    if ($params !== null) {
      $this->params = array_merge($this->params, $params);
    }
    $sql = $this->sql;
    foreach ($this->params as $key => $value) {
      if (is_string($key)) {
        $sql = str_replace($key, $this->quote($value), $sql);
      } else {
        $sql = $this->replaceQueryPosition($sql, $this->quote($value));
      }
    }
    $this->result = $this->rmq->query($sql);
    return $this->result;
  }

  public function fetch($fetch_style = null) {
    if ($this->result === null) {
      return false;
    }
    return $this->result->fetch($fetch_style);
  }

  public function fetchAll($fetch_style = null) {
    if ($this->result === null) {
      return false;
    }
    return $this->result->fetchAll($fetch_style);
  }

  public function fetchColumn($column_number = 0) {
    if ($this->result === null) {
      return false;
    }
    return $this->result->fetchColumn($column_number);
  }

  public function rowCount() {
    if ($this->result === null) {
      return 0;
    }
    return count($this->result->fetchAll());
  }

  private function quote($value) {
    if (is_null($value)) {
      return 'NULL';
    }
    if (is_bool($value)) {
      return $value ? '1' : '0';
    }
    if (is_int($value) || is_float($value)) {
      return $value;
    }
    return "'" . addslashes($value) . "'";
  }

  private function replaceQueryPosition($query, $value) {
    $pos = strpos($query, '?');
    if ($pos !== false) {
      return substr_replace($query, $value, $pos, 1);
    }
    return $query;
  }

  public function closeCursor() {
    $this->result = null;
    return true;
  }
}

if (basename($_SERVER['SCRIPT_FILENAME']) == basename(__FILE__)) {
  if ($argc < 2) {
    echo "Usage: rmq_proxy <message> <destination>\n";
    echo "Example: rmq_proxy '{\"query\":\"SELECT * FROM appliances\"}' database\n";
    exit(1);
  }

  $rmq = new RMQClient();
  
  try {
    $message = json_decode($argv[1], true);
    if (json_last_error() !== JSON_ERROR_NONE) {
      throw new Exception("Invalid JSON message provided");
    }
    $destination = isset($argv[2]) ? $argv[2] : 'backend';
    echo "Sending message to $destination...\n";
    $correlation_id = $rmq->sendRequest($message, $destination);
    echo "Waiting for response...\n";
    $response = $rmq->waitForResponse($correlation_id);
    if ($response) {
      echo "Response received:\n";
      echo json_encode($response, JSON_PRETTY_PRINT) . "\n";
      exit(0);
    } else {
      echo "Error: Request timed out\n";
      exit(1);
    }
  } catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    exit(1);
  }
}
