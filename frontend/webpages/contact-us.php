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
        <div class="container py-5">
            <div class="row">
                <div class="col-md-8 col-xl-6 text-center mx-auto">
                    <h2 class="display-6 fw-bold mb-4">Got any <span class="underline">questions</span>?</h2>
                    <p class="text-muted">Our team is always here to help. Send us a message and we'll get back to you shortly.</p>
                </div>
            </div>
            <div class="row d-flex justify-content-center">
                <div class="col-md-6">
                    <div>
                        <form class="p-3 p-xl-4" method="post" data-bs-theme="light">
                            <div class="mb-3"><input class="shadow form-control" type="text" id="name-1" name="name" placeholder="Name"></div>
                            <div class="mb-3"><input class="shadow form-control" type="email" id="email-1" name="email" placeholder="Email"></div>
                            <div class="mb-3"><textarea class="shadow form-control" id="message-1" name="message" rows="6" placeholder="Message"></textarea></div>
                            <div><button class="btn btn-primary shadow d-block w-100" type="submit">Send </button></div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </section>
    <section class="py-4 py-xl-5 mb-5">
        <div class="container">
            <div class="row mb-2">
                <div class="col-md-8 col-xl-6 text-center mx-auto">
                    <h2 class="display-6 fw-bold mb-5"><span class="pb-3 underline">FAQ<br></span></h2>
                </div>
            </div>
            <div class="row mb-2">
                <div class="col-md-8 mx-auto">
                    <div class="accordion text-muted" role="tablist" id="accordion-1">
                        <div class="accordion-item">
                            <h2 class="accordion-header" role="tab"><button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#accordion-1 .item-1" aria-expanded="true" aria-controls="accordion-1 .item-1">What appliances do you cover?</button></h2>
                            <div class="accordion-collapse collapse show item-1" role="tabpanel" data-bs-parent="#accordion-1">
                                <div class="accordion-body">
                                    <p>We cover a wide range of appliances, including:</p>
                                    <ul>
                                        <li>Refrigerators</li>
                                        <li>Washing Machines</li>
                                        <li>Dryers</li>
                                        <li>Microwaves</li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                        <div class="accordion-item">
                            <h2 class="accordion-header" role="tab"><button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#accordion-1 .item-2" aria-expanded="false" aria-controls="accordion-1 .item-2">Can I purchase replacement parts through Applicare?</button></h2>
                            <div class="accordion-collapse collapse item-2" role="tabpanel" data-bs-parent="#accordion-1">
                                <div class="accordion-body">
                                    <p class="mb-0">Yes! Once we identify the issue, we’ll recommend compatible parts and link you to trusted retailers for purchase.</p>
                                </div>
                            </div>
                        </div>
                        <div class="accordion-item">
                            <h2 class="accordion-header" role="tab"><button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#accordion-1 .item-3" aria-expanded="false" aria-controls="accordion-1 .item-3">How does the troubleshooting feature work?</button></h2>
                            <div class="accordion-collapse collapse item-3" role="tabpanel" data-bs-parent="#accordion-1">
                                <div class="accordion-body">
                                    <p class="mb-0">Our troubleshooting tool walks you through a series of questions to identify the problem with your appliance. Based on your answers, we offer possible solutions or guide you to the appropriate repair resources.</p>
                                </div>
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