<?php
// checks database connection cause it is needed for troubleshooting
require_once('../src/database-applicare.php');

// Start the session only if it's not already active
if (session_status() === PHP_SESSION_NONE) {
    session_start();
  }

$is_logged_in = isset($_SESSION['user_id']) && $_SESSION['user_id'] > 0;

// echo "Session User ID: " . $_SESSION['user_id']; // Debugging

  //   var_dump($_GET);

//   // Debugging for the values captured
// echo "Appliance ID: " . htmlspecialchars($_GET['appliance_id']) . "<br>";
// echo "Appliance Type: " . htmlspecialchars($_GET['appliance_type']) . "<br>";
// echo "Brand: " . htmlspecialchars($_GET['brand']) . "<br>";
// echo "Model: " . htmlspecialchars($_GET['model']) . "<br>";
// echo "Area: " . htmlspecialchars($_GET['area']) . "<br>";
// echo "Problem: " . htmlspecialchars($_GET['problem']) . "<br>";

// Check if all required parameters are present
if (isset($_GET['appliance_id'], $_GET['brand'], $_GET['model'], $_GET['area'], $_GET['problem'])) {
    $appliance_id = $_GET['appliance_id'];
    $brand = $_GET['brand'];
    $model_ = $_GET['model'];
    $part_id = $_GET['area'];


    // Database connection and fetching relevant parts
    $query = '
        SELECT 
            cp.id AS problem_id, 
            cp.problem_description, 
            cp.solution_steps, 
            cp.area,
            p.id AS part_id,
            p.name,
            p.description,
            p.image_url,
            p.video_url,
            p.purchase_url
        FROM common_problems cp
        JOIN appliances a ON cp.appliance_id = a.id
        JOIN parts p ON p.id = cp.part_id
        WHERE a.type = :appliance_type
        AND a.brand = :brand
        AND a.model = :model
        AND cp.area = :area
        AND cp.problem_description = :problem_description
    ';



        $statement = $db->prepare($query);
        $statement->bindValue(':appliance_type', $_GET['appliance_type'], PDO::PARAM_STR);
        $statement->bindValue(':brand', $_GET['brand'], PDO::PARAM_STR);
        $statement->bindValue(':model', $_GET['model'], PDO::PARAM_STR);
        $statement->bindValue(':area', $_GET['area'], PDO::PARAM_STR);
        $statement->bindValue(':problem_description', $_GET['problem'], PDO::PARAM_STR);

        $statement->execute();
        $parts = $statement->fetchAll(PDO::FETCH_ASSOC);
        // var_dump($parts);  // Check the fetched parts


    if (!$parts) {
        echo "No parts found. Check database entries and query conditions.";
    } 
    // else {
    //     var_dump($parts); // Display fetched parts for debugging
    // }
    
    $statement->closeCursor();

    // Check if parts are found for the selected issue
    if ($parts) {
        // Use the first part found as the recommended part
        $recommended_part = $parts[0];
        $problem_id = $recommended_part['problem_id'];  // Set problem_id here
    } else {
        // No parts found
        $recommended_part = null;
    }
} else {
    // If required parameters are missing, redirect to 'our-services.php'
    header('Location: our-services.php');
    exit;
}

// Handle the review form submission
if (isset($_POST['submit_review'])) {
    var_dump($_POST);
    if ($is_logged_in) {
        $user_id = $_SESSION['user_id'];
        $part_id = $_POST['part_id'];
        $problem_id = $_POST['problem_id'];
        $rating = $_POST['rating'];
        $fixed_issue = $_POST['fixed_issue'];
        $review_text = $_POST['review_text']; // Correct the variable name

        // Perform the necessary insert/update query to save the review
        $query = "INSERT INTO part_reviews (user_id, part_id, problem_id, rating, fixed_issue, review_text) 
                VALUES (:user_id, :part_id, :problem_id, :rating, :fixed_issue, :review_text)";

        $statement = $db->prepare($query);
        $statement->bindValue(':user_id', $user_id, PDO::PARAM_INT);
        $statement->bindValue(':part_id', $part_id, PDO::PARAM_INT);
        $statement->bindValue(':problem_id', $problem_id, PDO::PARAM_INT);
        $statement->bindValue(':rating', $rating, PDO::PARAM_INT);
        $statement->bindValue(':fixed_issue', $fixed_issue, PDO::PARAM_INT);
        $statement->bindValue(':review_text', $review_text, PDO::PARAM_STR); // Corrected here
        if ($statement->execute()) {
            echo "Review submitted successfully!";
            header("Location: " . $_SERVER['PHP_SELF']);
            exit();
        } else {
            echo "Error submitting review! " . implode(" - ", $statement->errorInfo());
        }
    }
    
}

// Handle the bookmark functionality
// Handle the bookmark functionality
if (isset($_POST['bookmark'])) {
    if ($is_logged_in) {
        $user_id = $_SESSION['user_id'];
        $part_id = $_POST['part_id'];

        // Check if the part is already bookmarked by the user
        $check_query = "SELECT COUNT(*) FROM saved_parts WHERE user_id = :user_id AND part_id = :part_id";
        $check_statement = $db->prepare($check_query);
        $check_statement->bindValue(':user_id', $user_id, PDO::PARAM_INT);
        $check_statement->bindValue(':part_id', $part_id, PDO::PARAM_INT);
        $check_statement->execute();
        $already_bookmarked = $check_statement->fetchColumn();

        if ($already_bookmarked) {
            // If the part is already bookmarked, show an alert
            echo "<script>alert('This part is already bookmarked!');</script>";
            header("Location: " . $_SERVER['REQUEST_URI']);
            exit; // Ensure no further code is executed 
        } else {
            // Save the part to the user's saved parts
            $query = "INSERT INTO saved_parts (user_id, part_id) VALUES (:user_id, :part_id)";
            $statement = $db->prepare($query);
            $statement->bindValue(':user_id', $user_id, PDO::PARAM_INT);
            $statement->bindValue(':part_id', $part_id, PDO::PARAM_INT);
            if ($statement->execute()) {
                echo "<script>alert('Part bookmarked successfully!');</script>";
            } else {
                echo "<script>alert('Error: " . implode(" - ", $statement->errorInfo()) . "');</script>";
            }
        }

        // Redirect to prevent form resubmission
        header("Location: " . $_SERVER['REQUEST_URI']);
        exit;
    } else {
        echo "<script>alert('You must be logged in to bookmark this part.');</script>";
    }
}

?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recommended Parts</title>
    <link rel="stylesheet" href="assets/bootstrap/css/bootstrap.min.css">
</head>
<body>
    <?php include('../common/header.php'); ?>

    <div class="container py-5">
        <h1 class="text-center mb-4">Recommended Part</h1>
        
        <?php if ($recommended_part): ?>
            <div class="card mx-auto" style="max-width: 600px;">
                <img src="<?= htmlspecialchars($recommended_part['image_url']); ?>" class="card-img-top mx-auto d-block" alt="Part Image">
                <div class="card-body text-center">
                    <h5 class="card-title"><?= htmlspecialchars($recommended_part['name']); ?></h5>
                    <p class="card-title"><?= htmlspecialchars($recommended_part['description']); ?></p>
                    <div class="d-flex justify-content-center gap-2">
                        <a href="<?= htmlspecialchars($recommended_part['purchase_url']); ?>" class="btn btn-primary" target="_blank">Buy Part</a>

                        <?php if ($recommended_part['video_url']): ?>
                            <a href="<?= htmlspecialchars($recommended_part['video_url']); ?>" class="btn btn-secondary" target="_blank">Watch Instructions</a>

                        <?php endif; ?>
                    </div>
                </div>
            </div>

             <!-- Bookmark button (only available if logged in) -->
             <?php if ($is_logged_in): ?>
                <form method="POST" class="text-center mt-3">
                <input type="hidden" name="user_id" value="<?= isset($_SESSION['user_id']) ? $_SESSION['user_id'] : '' ?>">
                <input type="hidden" name="part_id" value="<?= $recommended_part ? $recommended_part['part_id'] : '' ?>">                    <button type="submit" name="bookmark" class="btn btn-warning">Bookmark This Part</button>
                </form>
            <?php else: ?>
                <p class="text-center mt-3">You need to <a href="login.php">log in</a> to bookmark this part.</p>
            <?php endif; ?>
            
        <?php else: ?>
            <div class="alert alert-warning text-center">
                No recommended parts found for the selected issue.
            </div>
        <?php endif; ?>

        <h3 class="mt-5 text-center">Find Nearby Handymen</h3>

        <!-- Google Maps Iframe to search for Handymen -->
        <?php
        // Example location for searching handymen, could be dynamic based on 'area_id'
        $location = "New+Jersey"; // You could dynamically populate this
        $searchQuery = "handyman+" . urlencode($location);
        ?>
        <div class="text-center">
            <!-- Static Google Map with predefined coordinates -->
                <iframe 
                    src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d12091.640837505438!2d-74.19203265527406!3d40.74200124412969!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89c2534cc006098b%3A0xfac623bce8f114d8!2sMaple%20Hall%20NJIT!5e0!3m2!1sen!2sus!4v1696634464882!5m2!1sen!2sus" 
                    width="100%" 
                    height="500" 
                    style="border:0;" 
                    allowfullscreen="" 
                    loading="lazy">
                </iframe>
        </div>
    </div>

    <!-- Review Form -->
    <h3 class="text-center" mt-5 mb-4>Leave a Review</h3>
        <form method="POST" action="" class="mx-auto" style="max-width: 600px; border: 1px solid #ccc; padding: 20px; border-radius:8px; background-color: #f9f9f9;">
            <input type="hidden" name="user_id" value="<?= isset($_SESSION['user_id']) ? $_SESSION['user_id'] : '' ?>">
            <input type="hidden" name="part_id" value="<?= $recommended_part ? $recommended_part['part_id'] : '' ?>">
            <input type="hidden" name="problem_id" value="<?= $problem_id; ?>">
            
            <!-- <pre><?php var_dump($_SESSION['user_id'], $recommended_part, $problem_id); ?></pre> -->

            <div class="mb-3">
                <label for="rating" class="form-label">Rating</label>
                <select class="form-select" id="rating" name="rating" required>
                    <option value="1">1 - Poor</option>
                    <option value="2">2 - Fair</option>
                    <option value="3">3 - Good</option>
                    <option value="4">4 - Very Good</option>
                    <option value="5">5 - Excellent</option>
                </select>
            </div>
            <div class="mb-3">
                <label for="fixed_issue" class="form-label">Did this fix your issue?</label>
                <select class="form-select" id="fixed_issue" name="fixed_issue" required>
                    <option value="1">Yes</option>
                    <option value="0">No</option>
                </select>
            </div>
            <div class="mb-3">
                <label for="comment" class="form-label">Your Review</label>
                <textarea class="form-control" id="comment" name="review_text" rows="4" required></textarea>
            </div>
            <button type="submit" name="submit_review" class="btn btn-primary">Submit Review</button>
        </form>
    </div>

    <?php include('../common/footer.php'); ?>


    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
