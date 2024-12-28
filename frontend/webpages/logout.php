<?php
  // Start the session only if it's not already active
  if (session_status() === PHP_SESSION_NONE) {
    session_start();
  }

  // destorys session to log user out
  session_unset();
  session_destroy();

  //redirect to the homepage or login page
  header("Location: index.php");
  exit();

?>