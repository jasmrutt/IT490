<?php

// Include database connection
require_once('../src/database-applicare.php'); 

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$is_logged_in = isset($_SESSION['user_id']);
$saved_parts = [];

if ($is_logged_in) {
    $user_id = $_SESSION['user_id'];

    // Query to fetch saved parts
    $query = "SELECT 
                p.id, 
                p.name, 
                p.type, 
                p.area, 
                p.description, 
                p.image_url, 
                p.purchase_url, 
                p.video_url, 
                sp.notes
              FROM saved_parts sp
              JOIN parts p ON sp.part_id = p.id
              WHERE sp.user_id = :user_id";

    // Prepare the statement to prevent SQL injection
    if ($stmt = $db->prepare($query)) {
        $stmt->bindValue(':user_id', $user_id, PDO::PARAM_INT); // Bind the user_id parameter
        $stmt->execute();
        $saved_parts = $stmt->fetchAll(PDO::FETCH_ASSOC);

        if (!$saved_parts) {
            echo "No saved parts found for User ID: " . htmlspecialchars($user_id);
        }
        $stmt->closeCursor();
    } else {
        echo "Error preparing the query.";
    }
} else {
    echo "You are not logged in.";
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
    <header class="pt-5">
        <div class="container pt-4 pt-xl-5">
            <div class="row pt-5">
                <div class="col-md-8 text-center text-md-start mx-auto">
                    <div class="text-center">
                        <h1 class="display-4 fw-bold mb-5">Saved Parts</h1>
                    </div>
                </div>
            </div>
        </div>
    </header>
    <div class="container mt-5">
   
        <?php if (count($saved_parts) > 0): ?>
            <div class="row">
                <?php foreach ($saved_parts as $part): ?>
                    <div class="col-md-4">
                        <div class="card">
                            <?php if ($part['image_url']): ?>
                                <img src="<?= htmlspecialchars($part['image_url']); ?>" class="card-img-top" alt="<?= htmlspecialchars($part['name']); ?>">
                            <?php endif; ?>
                        <div class="card-body">
                            <h5 class="card-title"><?= htmlspecialchars($part['name']); ?></h5>
                            <p class="card-text"><?= htmlspecialchars($part['description']); ?></p>
                            <p><strong>Type:</strong> <?= htmlspecialchars($part['type']); ?></p>
                            <p><strong>Area:</strong> <?= htmlspecialchars($part['area']); ?></p>

                        <?php if ($part['purchase_url']): ?>
                            <a href="<?= htmlspecialchars($part['purchase_url']); ?>" class="btn btn-primary" target="_blank">Buy Now</a>
                        <?php endif; ?>

                        <?php if ($part['video_url']): ?>
                            <a href="<?= htmlspecialchars($part['video_url']); ?>" class="btn btn-secondary" target="_blank">Watch Video</a>
                        <?php endif; ?>

                        <?php if ($part['notes']): ?>
                            <div class="mt-3">
                                <strong>Notes:</strong>
                                <p><?= nl2br(htmlspecialchars($part['notes'])); ?></p>
                            </div>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
        <?php endforeach; ?>
        </div>
    <?php else: ?>
        <p>You have no saved parts.</p>
    <?php endif; ?>

    </div>

    <?php include('../common/footer.php'); ?>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>