<?php

    // connecting to the database
    require_once('../src/database-applicare.php');

    if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // getting the data from the form
        $first_name = filter_input(INPUT_POST, 'first_name');
        $last_name = filter_input(INPUT_POST, 'last_name');
        $email = filter_input(INPUT_POST, 'email', FILTER_SANITIZE_EMAIL);
        $password_hash = filter_input(INPUT_POST, 'password_hash');
        $security_question = filter_input(INPUT_POST, 'security_question');
        $security_answer = filter_input(INPUT_POST, 'security_answer');

        // Validate required fields
        if (empty($first_name) || empty($last_name) || empty($email) || empty($password_hash) || empty($security_question) || empty($security_answer)) {
            echo "All fields are required!";

        } else{
            // Checks if email already exists 
            $query = "SELECT * FROM users WHERE email = :email";
            $statement = $db->prepare($query);
            $statement->bindValue(':email', $email);
            $statement->execute();
            $count = $statement->fetchColumn();

            if($count > 0){
                echo "<p class='text-danger text-center'>Email is already registered. Please log in or use another email.</p>";

            }else{
                $password_hash = password_hash($password_hash, PASSWORD_DEFAULT);
                $security_answer_hash = password_hash($security_answer, PASSWORD_DEFAULT);

                // insert data from form into the database
                $query = 'INSERT INTO users (first_name, last_name, email, password_hash, security_question, security_answer_hash)
                VALUES
                (:first_name, :last_name, :email, :password_hash, :security_question, :security_answer_hash)';

                $statement = $db->prepare($query);
                $statement->bindValue(':first_name', $first_name);
                $statement->bindValue(':last_name', $last_name);
                $statement->bindValue(':email', $email);
                $statement->bindValue(':password_hash', $password_hash);
                $statement->bindValue(':security_question', $security_question);
                $statement->bindValue(':security_answer_hash', $security_answer_hash);
                $success = $statement->execute();
                $statement->closeCursor();

                try {
                    if ($success) {
                        echo "<p class='text-success text-center'>Sign up successful! You can now <a href='login.php'>log in</a>.</p>";
                        header('Location: login.php'); // Redirect to the login page
                        exit();
                    } else {
                        echo "<p class='text-danger text-center'>Error signing up. Please try again later.</p>";
                    }
                } catch (PDOException $e) {
                    echo "<p class='text-danger text-center'>Error: " . $e->getMessage() . "</p>";
                }

            }
            
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

    <section class="py-5 mt-5">
        <div class="container py-4 py-xl-5">
            <section class="position-relative py-4 py-xl-5">
                <div class="container">
                    <div class="row mb-5">
                        <div class="col-md-8 col-xl-6 text-center mx-auto">
                            <h2>Sign Up</h2>
                            <?php if (!empty($error)) echo "<p class='text-danger'>$error</p>"; ?>
                            </div>
                    </div>
                    <div class="row d-flex justify-content-center">
                        <div class="col-md-8 col-xl-6">
                            <div class="card mb-5">
                                <div class="card-body d-flex flex-column align-items-center">
                                    <div class="bs-icon-xl bs-icon-circle bs-icon-primary bs-icon my-4"><svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" fill="currentColor" viewBox="0 0 16 16" class="bi bi-person">
                                            <path d="M8 8a3 3 0 1 0 0-6 3 3 0 0 0 0 6m2-3a2 2 0 1 1-4 0 2 2 0 0 1 4 0m4 8c0 1-1 1-1 1H3s-1 0-1-1 1-4 6-4 6 3 6 4m-1-.004c-.001-.246-.154-.986-.832-1.664C11.516 10.68 10.289 10 8 10c-2.29 0-3.516.68-4.168 1.332-.678.678-.83 1.418-.832 1.664z"></path>
                                        </svg></div>
                                    <p>Sign Up</p>
                                    <form class="text-center" method="post">
                                        <div class="mb-3">
                                            <label for="first_name" class="form-label text-start w-100">First Name</label>
                                            <input id="first_name" class="form-control" type="text" name="first_name" placeholder="John" required>
                                        </div>
                                        <div class="mb-3">
                                            <label for="last_name" class="form-label text-start w-100">Last Name</label>
                                            <input id="last_name" class="form-control" type="text" name="last_name" placeholder="Doe" required>
                                        </div>
                                        <div class="mb-3">
                                            <label for="email" class="form-label text-start w-100">Email</label>
                                            <input id="email" class="form-control" type="text" name="email" placeholder="johndoe@gmail.com" required>
                                        </div>
                                        <div class="mb-3">
                                            <label for="password_hash" class="form-label text-start w-100">Password</label>
                                            <input id="password_hash" class="form-control" type="password" name="password_hash" placeholder="Password123!" required>
                                        </div>
                                        <div class="mb-3">
                                            <label for="security_question" class="form-label text-start w-100">Select a Security Question</label>
                                            <select id="security_question" name="security_question" class="form-control" required>
                                                <option value="" disabled selected>Choose a Question</option>
                                                <option value="What year was your father born?">What year was your father born?</option>
                                                <option value="What is your favorite color?">What is your favorite color?</option>
                                                <option value="What is the name of your first pet?">What is the name of your first pet?</option>
                                                <option value="What elementary school did you attend?">What elementary school did you attend?</option>
                                                </ul>
                                            </select>
                                        </div>
                                        <div class="mb-3">
                                            <label for="security_answer" class="form-label text-start w-100">Answer</label>
                                            <input id="security_answer" class="form-control" type="text" name="security_answer" placeholder="Blue" required>
                                        </div>
                                        <div class="mb-3">
                                            <button class="btn btn-primary d-block w-100" role="button" href="login.php">Sign Up</button>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    </section>
    <?php include('../common/footer.php'); ?>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.reflowhq.com/v2/toolkit.min.js"></script>
    <script src="assets/js/bs-init.js"></script>
    <script src="assets/js/startup-modern.js"></script>
</body>

</html>
