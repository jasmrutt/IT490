<?php
  require_once('../src/database-applicare.php');
  $email = '';
  $security_question = '';
  $security_answer = '';
  $new_password = '';
  $error = '';


  // Start the session only if it's not already active
  if (session_status() === PHP_SESSION_NONE) {
    session_start();
  }
  error_log("test");
  //error_log("Value of email: " . print_r($email, true),3, "/root/Capstone-Group-10/frontend/webpages/error.log");
  if($_SERVER['REQUEST_METHOD'] == 'POST'){
    
    $email = filter_var(trim($_POST['email']), FILTER_SANITIZE_EMAIL);
    $error = '';

    if(empty($email)){
        echo "Email is required";
    }else{
        try{
            // checks if the email exists in users table
            $sql = "SELECT * FROM users WHERE email = ?";
            $stmt = $db->prepare($sql);
            $stmt->execute([$email]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);

            if($user){
                $_SESSION['email'] = $email;
                $_SESSION['user_id'] = $user['user_id'];
                $security_question = $user['security_question'];
            } else {
                $error = "No user with that email address.";
            }

        } catch(PDOException $e){
            echo "Database Error: " . $e->getMessage();
        }
    }
  }

  if (isset($_POST['security_answer']) && isset($_POST['new_password'])){

    if(isset($_SESSION['email'])){
        $email = $_SESSION['email'];
    }else{
        echo "Session error: Email not found. Please start the process again.";
        exit();
    }

    $security_answer = trim($_POST['security_answer']);
    $new_password = trim($_POST['new_password']);
    $error = '';

    if(empty($security_answer) || empty($new_password)) {
        echo "Both answer and new password are required!";
    } else {
        try {
             // checks if the user exists again in users table
             $sql = "SELECT * FROM users WHERE email = ?";
             $stmt = $db->prepare($sql);
             $stmt->execute([$email]);
             $user = $stmt->fetch(PDO::FETCH_ASSOC);

             if($user){
                if (password_verify($security_answer, $user['security_answer_hash'])) {
                    // if answer matches, allow password change
                    $hashed_password = password_hash($new_password, PASSWORD_DEFAULT);
                    $sql = "UPDATE users SET password_hash = ? WHERE email = ?";
                    $stmt = $db->prepare($sql);
                    $stmt->execute([$hashed_password, $email]);
                    echo "Password updated successfully";
                    header("Location: login.php");
                    exit();
                } else {
                    $error = "Incorrect security answer.";
                }
             }else{
                $error = "User not found.";
             }
            } catch (PDOException $e){
                echo "Database Error: " . $e->getMessage();
            }

    }
  }

?>
<!DOCTYPE html>
<html data-bs-theme="light" lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, shrink-to-fit=no">
    <title>Password Recovery - Applicare</title>
    <link rel="stylesheet" href="assets/bootstrap/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.reflowhq.com/v2/toolkit.min.css">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Raleway:300italic,400italic,600italic,700italic,800italic,400,300,600,700,800&amp;display=swap">
    <link rel="stylesheet" href="assets/css/bs-theme-overrides.css">
    <link rel="stylesheet" href="assets/css/Login-Form-Basic-icons.css">
</head>

<body>
    <?php include('../common/header.php'); ?>

    <section class="py-5 mt-5">
        <div class="container py-4 py-xl-5">
            <?php if (empty($email)): ?>
                <div class="text-center">
                    <h2>Password Recovery</h2>
                    <p class="w-lg-50">Enter your email address to reset your password.</p>
                    <form method="post">
                        <div class="mb-3">
                            <input class="form-control" type="email" name="email" placeholder="Enter your email" required>
                        </div>
                        <div class="mb-3">
                            <button class="btn btn-primary d-block w-100" type="submit">Send Recovery Email</button>
                        </div>
                    </form>
                </div>
            <?php else: ?>
                <!-- security question form -->
                 <div class="text-center">
                    <h2>Security Question</h2>
                    <p>Answer the security question to reset your password.</p>
                    <form method="post">
                        <div class="mb-3">
                            <p><strong><?php echo $security_question; ?></strong></p>
                            <input class="form-control" type="text" name="security_answer" placeholder="Your answer" required>
                        </div>
                        <div class="mb-3">
                            <input class="form-control" type="password" name="new_password" placeholder="New password" required>
                        </div>
                        <?php if (!empty($error)) : ?>
                            <div class="alert alert-danger"><?php echo $error; ?></div>
                        <?php endif; ?>
                        <div class="mb-3">
                            <button class="btn btn-primary d-block w-100" type="submit">Reset Password</button>
                        </div>
                    </form>
                </div>
            <?php endif; ?>
        </div>
    </section>

    <?php include('../common/footer.php'); ?>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.reflowhq.com/v2/toolkit.min.js"></script>
    <script src="assets/js/bs-init.js"></script>
    <script src="assets/js/startup-modern.js"></script>
</body>

</html>
