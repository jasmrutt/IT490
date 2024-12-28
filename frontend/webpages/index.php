<?php
    require_once('../src/database-applicare.php');
    $email = '';

  // Start the session only if it's not already active
  if (session_status() === PHP_SESSION_NONE) {
    session_start();
  }
  if($_SERVER['REQUEST_METHOD'] == 'POST'){
    $email = filter_var(trim($_POST['email']), FILTER_SANITIZE_EMAIL);

    try {
        // Check if the user exists
        $sql = "SELECT * FROM users WHERE email = ?";
        $stmt = $db->prepare($sql);
        $stmt->execute([$email]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user) {
            header("Location: login.php");
            exit;
        }else{
            header("Location: signup.php");
            exit;
        }
    } catch (\Throwable $e) {
        echo "Database Error: " . $e->getMessage();
    }
  }
?>

<!DOCTYPE html>
<html data-bs-theme="light" lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, shrink-to-fit=no">
    <title>Applicare</title>
    <link rel="stylesheet" href="assets/bootstrap/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.reflowhq.com/v2/toolkit.min.css">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Raleway:300italic,400italic,600italic,700italic,800italic,400,300,600,700,800&amp;display=swap">
    <link rel="stylesheet" href="assets/css/bs-theme-overrides.css">
    <link rel="stylesheet" href="assets/css/Login-Form-Basic-icons.css">
</head>

<body>
    <?php include('../common/header.php'); ?>

    <header class="pt-5">
        <div class="container pt-4 pt-xl-5">
            <div class="row pt-5">
                <div class="col-md-8 text-center text-md-start mx-auto">
                    <div class="text-center">
                        <h1 class="display-4 fw-bold mb-5">Troubleshoot & Repair Your Home Appliances with Ease.</h1>
                        <p class="fs-5 text-muted mb-5">Applicare helps you troubleshoot and repair common household appliances yourself, saving time and money. With user-friendly guides, parts recommendations, and nearby repair shop suggestions, managing your home appliances has never been easier.</p>
                        <form class="d-flex justify-content-center flex-wrap" method="post" data-bs-theme="light">
                            <div class="shadow-lg mb-3"><input class="form-control" type="email" name="email" placeholder="Your Email"></div>
                            <div class="shadow-lg mb-3"><button class="btn btn-primary" type="submit">Get Started </button></div>
                        </form>
                    </div>
                </div>
                <div class="col-12 col-lg-10 mx-auto">
                    <div class="text-center position-relative"><img class="img-fluid" src="assets/img/illustrations/meeting.svg" style="width: 800px;"></div>
                </div>
            </div>
        </div>
    </header>
    <section>
        <div class="container py-4 py-xl-5">
            <div class="row gy-4 row-cols-1 row-cols-md-2 row-cols-lg-3">
                <div class="col">
                    <div class="card border-light border-1 d-flex justify-content-center p-4">
                        <div class="card-body">
                            <div class="bs-icon-lg bs-icon-rounded bs-icon-secondary d-flex flex-shrink-0 justify-content-center align-items-center d-inline-block mb-4 bs-icon"><svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icon-tabler-school">
                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"></path>
                                    <path d="M22 9l-10 -4l-10 4l10 4l10 -4v6"></path>
                                    <path d="M6 10.6v5.4a6 3 0 0 0 12 0v-5.4"></path>
                                </svg></div>
                            <div>
                                <h4 class="fw-bold">Step-by-Step Guides</h4>
                                <p class="text-muted">Easily follow our step-by-step troubleshooting and repair guides for common appliances like refrigerators, dishwashers, and washing machines. No professional needed!</p>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col">
                    <div class="card border-light border-1 d-flex justify-content-center p-4">
                        <div class="card-body">
                            <div class="bs-icon-lg bs-icon-rounded bs-icon-secondary d-flex flex-shrink-0 justify-content-center align-items-center d-inline-block mb-4 bs-icon"><svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icon-tabler-school">
                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"></path>
                                    <path d="M22 9l-10 -4l-10 4l10 4l10 -4v6"></path>
                                    <path d="M6 10.6v5.4a6 3 0 0 0 12 0v-5.4"></path>
                                </svg></div>
                            <div>
                                <h4 class="fw-bold">Find Replacement Parts</h4>
                                <p class="text-muted">Easily find the replacement parts for your appliances directly from our app. We recommend trusted suppliers and ensure fast delivery to get your appliances working again.</p>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col">
                    <div class="card border-light border-1 d-flex justify-content-center p-4">
                        <div class="card-body">
                            <div class="bs-icon-lg bs-icon-rounded bs-icon-secondary d-flex flex-shrink-0 justify-content-center align-items-center d-inline-block mb-4 bs-icon"><svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icon-tabler-school">
                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"></path>
                                    <path d="M22 9l-10 -4l-10 4l10 4l10 -4v6"></path>
                                    <path d="M6 10.6v5.4a6 3 0 0 0 12 0v-5.4"></path>
                                </svg></div>
                            <div>
                                <h4 class="fw-bold">Nearby Repair Shops</h4>
                                <p class="text-muted">Need professional help? Locate nearby repair shops for expert assistance. We help you find trusted technicians and repair services near your location.</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
   
    <?php include('../common/footer.php'); ?>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.reflowhq.com/v2/toolkit.min.js"></script>
    <script src="assets/js/bs-init.js"></script>
    <script src="assets/js/startup-modern.js"></script>
</body>

</html>