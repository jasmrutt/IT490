/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19-11.4.3-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: applicare
-- ------------------------------------------------------
-- Server version	11.4.3-MariaDB-1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Table structure for table `appliances`
--

DROP TABLE IF EXISTS `appliances`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `appliances` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(255) NOT NULL,
  `brand` varchar(255) NOT NULL,
  `model` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `brand` (`brand`,`model`),
  KEY `type` (`type`),
  KEY `brand_2` (`brand`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `appliances`
--

LOCK TABLES `appliances` WRITE;
/*!40000 ALTER TABLE `appliances` DISABLE KEYS */;
INSERT INTO `appliances` VALUES
(1,'Washer','Whirlpool','WFW6620HW','A front-load washer with 4.5 cu. ft. capacity, intuitive controls, and an automatic detergent dispenser.','2024-12-19 01:11:26'),
(4,'Dryer','Samsung','DVE50R8500V','Electric dryer with steam sanitize, sensor dry, and 7.5 cu. ft. capacity.','2024-12-19 01:11:26'),
(7,'Refrigerator','LG','LFXS26596S','Smart French door refrigerator with InstaView and a 26 cu. ft. capacity.','2024-12-19 01:11:26'),
(10,'Microwave','Panasonic','NN-SN966S','A stainless steel countertop microwave with inverter technology and 2.2 cu. ft. capacity.','2024-12-19 01:11:26'),
(13,'Dishwasher','Bosch','SHXM63WS5N','A quiet, 44-decibel dishwasher with adjustable racks and a stainless steel tub.','2024-12-19 01:11:26'),
(16,'Oven','GE','JB655YKFS','A freestanding electric range with convection oven and smooth glass cooktop.','2024-12-19 01:11:26');
/*!40000 ALTER TABLE `appliances` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `common_problems`
--

DROP TABLE IF EXISTS `common_problems`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `common_problems` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `appliance_id` int(11) NOT NULL,
  `part_id` int(11) NOT NULL,
  `problem_description` text NOT NULL,
  `solution_steps` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `area` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `appliance_id` (`appliance_id`),
  KEY `part_id` (`part_id`),
  CONSTRAINT `common_problems_ibfk_1` FOREIGN KEY (`appliance_id`) REFERENCES `appliances` (`id`),
  CONSTRAINT `common_problems_ibfk_2` FOREIGN KEY (`part_id`) REFERENCES `parts` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=91 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `common_problems`
--

LOCK TABLES `common_problems` WRITE;
/*!40000 ALTER TABLE `common_problems` DISABLE KEYS */;
INSERT INTO `common_problems` VALUES
(37,1,1,'Water leakage during operation','Inspect the door seal for cracks or wear and replace if damaged.','2024-12-19 03:47:47','Door Seal'),
(40,1,4,'Water not draining','Check the water pump for blockages or damage and clean or replace if needed.','2024-12-19 03:47:47','Pump'),
(43,1,7,'Drum not rotating','Inspect the drive belt for damage or wear and replace if needed.','2024-12-19 03:47:47','Drum'),
(46,4,10,'Dryer not heating','Check the heating element for faults and replace if broken.','2024-12-19 03:47:47','Heating Element'),
(49,4,13,'Drum not spinning','Inspect the drum belt for wear or breakage and replace if necessary.','2024-12-19 03:47:47','Drum'),
(52,4,16,'Temperature too high or too low','Check the thermostat for calibration and replace if faulty.','2024-12-19 03:47:47','Thermostat'),
(55,7,19,'Refrigerator not cooling properly','Check the thermostat and adjust settings or replace if malfunctioning.','2024-12-19 03:47:47','Thermostat'),
(58,7,22,'Water dispenser not working','Replace the water filter if clogged or damaged.','2024-12-19 03:47:47','Water Filter'),
(61,7,25,'Refrigerator not cooling at all','Inspect the compressor for signs of failure and replace if necessary.','2024-12-19 03:47:47','Thermostat'),
(64,10,28,'Food not heating evenly','Check the turntable for proper movement and replace if damaged.','2024-12-19 03:47:47','Turntable'),
(67,10,31,'Microwave not heating','Inspect the magnetron for failure and replace if faulty.','2024-12-19 03:47:47','Magnetron'),
(70,10,34,'Microwave not starting','Ensure the door switch is functioning and replace if it fails to engage.','2024-12-19 03:47:47','Door Switch'),
(73,13,37,'Dishes not getting clean','Check the spray arm for blockages and clean or replace if necessary.','2024-12-19 03:47:47','Spray Arm'),
(76,13,40,'Dishwasher not draining','Inspect the drain pump for blockages and clean or replace if needed.','2024-12-19 03:47:47','Drain Pump'),
(79,13,43,'Dishwasher making noise','Check the dish rack for misalignment and ensure the drain pump is functioning properly.','2024-12-19 03:47:47','Dish Rack / Drain Pump'),
(82,16,46,'Oven not heating up','Inspect the oven element for damage and replace if needed.','2024-12-19 03:47:47','Oven Element'),
(85,16,49,'Oven temperature inconsistent','Check the control board for malfunction and replace if necessary.','2024-12-19 03:47:47','Control Board'),
(88,16,52,'Heat escaping from oven door','Inspect the oven door seal for wear or damage and replace if necessary.','2024-12-19 03:47:47','Oven Door Seal');
/*!40000 ALTER TABLE `common_problems` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `part_reviews`
--

DROP TABLE IF EXISTS `part_reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `part_reviews` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `part_id` int(11) NOT NULL,
  `problem_id` int(11) NOT NULL,
  `rating` tinyint(4) NOT NULL CHECK (`rating` between 1 and 5),
  `fixed_issue` tinyint(1) NOT NULL,
  `review_text` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`part_id`,`problem_id`),
  KEY `problem_id` (`problem_id`),
  KEY `idx_part_reviews_ratings` (`part_id`,`rating`),
  CONSTRAINT `part_reviews_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `part_reviews_ibfk_2` FOREIGN KEY (`part_id`) REFERENCES `parts` (`id`),
  CONSTRAINT `part_reviews_ibfk_3` FOREIGN KEY (`problem_id`) REFERENCES `common_problems` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `part_reviews`
--

LOCK TABLES `part_reviews` WRITE;
/*!40000 ALTER TABLE `part_reviews` DISABLE KEYS */;
/*!40000 ALTER TABLE `part_reviews` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `parts`
--

DROP TABLE IF EXISTS `parts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `parts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `appliance_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `area` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `purchase_url` varchar(255) DEFAULT NULL,
  `video_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `appliance_id` (`appliance_id`),
  KEY `type` (`type`),
  KEY `area` (`area`),
  CONSTRAINT `parts_ibfk_1` FOREIGN KEY (`appliance_id`) REFERENCES `appliances` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `parts`
--

LOCK TABLES `parts` WRITE;
/*!40000 ALTER TABLE `parts` DISABLE KEYS */;
INSERT INTO `parts` VALUES
(1,1,'Door Seal','Component','Door','Prevents water from leaking during operation. Check for tears or cracks.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(4,1,'Water Pump','Component','Interior','Pumps water out of the washer during the drain cycle.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(7,1,'Drive Belt','Component','Interior','Helps rotate the drum during the washing cycle.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(10,4,'Heating Element','Component','Interior','Heats the air that dries the clothes.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(13,4,'Drum Belt','Component','Interior','Moves the drum during the drying cycle.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(16,4,'Thermostat','Component','Interior','Controls the temperature inside the dryer.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(19,7,'Thermostat','Component','Interior','Controls the temperature settings of the refrigerator.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(22,7,'Water Filter','Accessory','Interior','Filters impurities from the water dispensed from the fridge.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(25,7,'Compressor','Component','Interior','Pumps refrigerant through the cooling coils to keep the fridge cold.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(28,10,'Turntable','Component','Interior','Rotates food for even heating in the microwave.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(31,10,'Magnetron','Component','Interior','Generates microwaves to cook the food.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(34,10,'Door Switch','Component','Door','Ensures the microwave operates only when the door is properly closed.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(37,13,'Spray Arm','Component','Interior','Sprays water to clean the dishes inside the dishwasher.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(40,13,'Dish Rack','Accessory','Interior','Holds dishes during the washing cycle.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(43,13,'Drain Pump','Component','Interior','Pumps water out of the dishwasher during the drain cycle.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(46,16,'Oven Element','Component','Interior','Heats the oven to the desired temperature.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(49,16,'Control Board','Component','Interior','Regulates the heating elements and settings of the oven.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45'),
(52,16,'Oven Door Seal','Component','Door','Prevents heat from escaping the oven when the door is closed.','url_to_image','url_to_purchase','url_to_video','2024-12-19 03:46:45');
/*!40000 ALTER TABLE `parts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `saved_parts`
--

DROP TABLE IF EXISTS `saved_parts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `saved_parts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `part_id` int(11) NOT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`part_id`),
  KEY `part_id` (`part_id`),
  CONSTRAINT `saved_parts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `saved_parts_ibfk_2` FOREIGN KEY (`part_id`) REFERENCES `parts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `saved_parts`
--

LOCK TABLES `saved_parts` WRITE;
/*!40000 ALTER TABLE `saved_parts` DISABLE KEYS */;
/*!40000 ALTER TABLE `saved_parts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `security_question` varchar(255) NOT NULL,
  `security_answer_hash` varchar(255) NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `failed_login_attempts` int(11) DEFAULT 0,
  `last_login_at` timestamp NULL DEFAULT NULL,
  `password_reset_token` varchar(255) DEFAULT NULL,
  `password_reset_expires` timestamp NULL DEFAULT NULL,
  `email_verified` tinyint(1) DEFAULT 0,
  `email_verification_token` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `email_verification_token` (`email_verification_token`),
  KEY `password_reset_token` (`password_reset_token`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES
(3,'and@the.slithey','$2y$10$a4m9k.QtEqXI6UjtcMYD6ugre5qfxkmik/sv9toY0cfOkvVuHnX6u','twas','brillig','What is your favorite color?','$2y$10$7S8FjJhfm/WLQDyt3GrHd.Wpz0MlJHSFV0XHXqtDkWwcCkfP5SkFS',1,0,NULL,NULL,NULL,0,NULL,'2024-12-19 03:16:06','2024-12-19 03:16:06'),
(4,'johndoe@gmail.com','$2y$10$khDXL2V0B8XQgXtAoqpy..elyK6lVts8ecuo8ZUU9nhbwNPNLcSyC','John','Doe','What is your favorite color?','$2y$10$uvQJeBmYyqhTDffqyCKDf.UkjGvFnrSGQAW939M.qLOVpytwBqHmC',1,0,NULL,NULL,NULL,0,NULL,'2024-12-19 04:40:29','2024-12-19 04:40:29'),
(6,'c','$2y$10$m6BNrOgBggSpIyRxqOoaqeTpGB6yFDOWAWSFoarixItAlpWLndZom','a','b','What year was your father born?','$2y$10$saQERR5gfXnP2e7e8mWmUeFZ1oRXQgA0T2TQQVPEIokUHkDIwhk8C',1,0,NULL,NULL,NULL,0,NULL,'2024-12-19 17:58:57','2024-12-19 17:58:57'),
(9,'and@seven.years','$2y$10$UCuam34EZsYQZ8KRpydAGudq2TFlJZbycufOQmmY7k4RK8NLtzAkC','four','score','What year was your father born?','$2y$10$J6EmilD4yXeR5wpqZDg2MeGaVUxANnYzUwvxgg46NkWLXFWf5HmgS',1,0,NULL,NULL,NULL,0,NULL,'2024-12-19 17:59:26','2024-12-19 17:59:26'),
(10,'johndoe@example.com','$2y$10$NhzrZ5s.JAfaUw8N9aqPBuUNKTPsNpGWnkvRvcn1VpHl89jBvngQS','Jonathan','Doenathan','What is your favorite color?','$2y$10$yksLcx/A4vkSXzwKjh00F.R9C1cYSHcPfRvCIsrX9Isago5MoIcce',1,0,NULL,NULL,NULL,0,NULL,'2024-12-19 19:21:08','2024-12-19 19:21:08');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2024-12-19 23:42:09
