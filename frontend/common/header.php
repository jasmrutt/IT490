<?php
  // Start the session only if it's not already active
  if (session_status() === PHP_SESSION_NONE) {
    session_start();
  }
  // Assuming you store the user's name in session when they log in
  $first_name = isset($_SESSION['first_name']) ? $_SESSION['first_name'] : '';
?>
<html lang="en">
  <head>
    <!-- Add Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
      /* Push the content down 70px */
      body {
        padding-top: 70px;
      }
    </style>
  </head>
  
  <body>
    <nav class="navbar navbar-expand-lg navbar-light bg-light fixed-top">
      <div class="container-fluid">
        <!-- Brand Name/Logo -->
        <a class="navbar-brand" href="index.php">
          <img src="assets/img/logo.png" alt="Applicare Logo" style="height: 40px;">
          Applicare
        </a>

        <!-- Navbar Toggler for Smaller Screens (Hamburger) -->
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
          <span class="navbar-toggler-icon"></span>
        </button>

        <!-- Navbar Links (Center-aligned) -->
        <div class="collapse navbar-collapse" id="navbarNav">
          <ul class="navbar-nav mx-auto"> <!-- mx-auto centers the navbar items -->
            <li class="nav-item">
              <a class="nav-link" href="index.php">Home</a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="about-us.php">About</a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="our-services.php">Our Services</a>
            </li>
          </ul>

          <!-- Right-aligned Section (Sign In, Star Icon, Cart) -->
          <ul class="navbar-nav ms-auto"> <!-- ms-auto pushes the items to the right -->
          <?php if (!empty($first_name)): ?>
              <!-- If user is logged in, display their name -->
              <li class="nav-item dropdown">
                <button class="nav-link dropdown-toggle" href="#" id="userDropdown" role="button" data-bs-toggle="dropdown" aria-expanded="true">
                  <?php echo htmlspecialchars($first_name); ?>
                </button>
                <ul class="dropdown-menu" aria-labelledby="userDropdown">
                  <li><a class="dropdown-item" href="logout.php">Logout</a></li>
                </ul>
              </li>
            <?php else: ?>
              <!-- If user is not logged in, show "Sign In" button -->
              <li class="nav-item">
                <a class="btn btn-primary" href="login.php" role="button">Sign In</a>
              </li>
            <?php endif; ?>
            <li class="nav-item">
              <a href="saved.php" class="nav-link">
                <svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icon-tabler-star" style="width: 21px; height: 20px;">
                  <path stroke="none" d="M0 0h24v24H0z" fill="none"></path>
                  <path d="M12 17.75l-6.172 3.245l1.179 -6.873l-5 -4.867l6.9 -1l3.086 -6.253l3.086 6.253l6.9 1l-5 4.867l1.179 6.873z"></path>
                </svg>
              </a>
            </li>
          </ul>
        </div>
      </div>
    </nav>

    <!-- Add Bootstrap JS -->
  </body>
</html>
