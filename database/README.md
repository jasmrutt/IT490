
# Database Overview

This document provides an overview of the database structure, including the tables and their purposes, as well as the key fields and relationships between tables. This database is designed to manage user data, appliance information, repair services, and troubleshooting logs.

## Table of Contents
- [Database Tables](#database-tables)
  - [users](#users)
  - [appliances](#appliances)
  - [parts](#parts)
  - [repair_services](#repair_services)
  - [troubleshooting_guides](#troubleshooting_guides)
  - [user_troubleshooting_logs](#user_troubleshooting_logs)
  - [user_activity](#user_activity)
- [Queries](#queries)
- [Getting Started](#getting-started)
- [Contributing](#contributing)
- [Database Setup](#database-setup)
---

## Database Tables

### **`users`**
This table stores information about the users who interact with the system.

| Column Name  | Data Type       | Description                             |
|--------------|-----------------|-----------------------------------------|
| `user_id`    | INT             | Primary key, unique user identifier.     |
| `user_name`  | VARCHAR(100)     | The username of the user.                |
| `privilege`  | ENUM('user', 'admin') | Role of the user (either user or admin). |
| `offtoken`   | VARCHAR(255)     | Security token for user authentication.  |

### **`appliances`**
This table stores information about the different appliances being tracked for troubleshooting and repairs.

| Column Name     | Data Type    | Description                              |
|-----------------|--------------|------------------------------------------|
| `appliance_id`  | INT          | Primary key, unique identifier for an appliance. |
| `appliance_name`| VARCHAR(255) | Name of the appliance.                   |

### **`parts`**
This table stores information about the parts used in appliances.

| Column Name  | Data Type    | Description                               |
|--------------|--------------|-------------------------------------------|
| `part_id`    | INT          | Primary key, unique part identifier.       |
| `part_name`  | VARCHAR(255) | Name of the part used in appliances.       |

### **`repair_services`**
This table logs the repair services available for different appliances.

| Column Name    | Data Type    | Description                              |
|----------------|--------------|------------------------------------------|
| `service_id`   | INT          | Primary key, unique identifier for a service. |
| `service_name` | VARCHAR(255) | Name of the repair service.              |

### **`troubleshooting_guides`**
This table provides troubleshooting steps for appliances.

| Column Name              | Data Type    | Description                              |
|--------------------------|--------------|------------------------------------------|
| `guide_id`               | INT          | Primary key, unique identifier for a guide. |
| `appliance_id`           | INT          | Foreign key, links to `appliances` table.   |
| `troubleshooting_steps`  | TEXT         | Step-by-step guide for troubleshooting.  |

### **`user_troubleshooting_logs`**
Logs actions taken by users when troubleshooting their appliances.

| Column Name         | Data Type    | Description                             |
|---------------------|--------------|-----------------------------------------|
| `log_id`            | INT          | Primary key, unique identifier for the log entry. |
| `user_id`           | INT          | Foreign key, links to `users` table.    |
| `appliance_id`      | INT          | Foreign key, links to `appliances` table. |
| `steps_taken`       | TEXT         | Troubleshooting steps performed by the user. |
| `timestamp`         | DATETIME     | When the troubleshooting occurred.      |

### **`user_activity`**
Tracks user activities, such as logging in, logging out, and actions taken within the system.

| Column Name           | Data Type    | Description                             |
|-----------------------|--------------|-----------------------------------------|
| `activity_id`         | INT          | Primary key, unique activity identifier.|
| `user_id`             | INT          | Foreign key, links to `users` table.    |
| `activity_type`       | VARCHAR(50)  | Type of activity (login, logout, etc.). |
| `activity_description`| TEXT         | Detailed description of the activity.   |
| `ip_address`          | VARCHAR(45)  | IP address of the user.                 |
| `timestamp`           | DATETIME     | Time of the activity.                   |

---

## Queries

### **List all tables:**
```sql
SHOW TABLES;
```

### **Describe a specific table:**
To get the structure of any table (for example, `users`):
```sql
DESCRIBE users;
```

### **List all columns of all tables:**
```sql
SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'your_database_name'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
```

---

## Getting Started

1. Install MariaDB and log in to the database.
2. Run the provided SQL scripts to create the tables.
3. Insert data and perform queries to manage user activities, appliance information, and troubleshooting logs.

### **Installation Example:**
```bash
mysql -u root -p
USE your_database_name;
```

---

## Contributing

If you'd like to contribute to the database design or add features, feel free to submit a pull request or create an issue.

---

## Database Setup
Here's an updated README section that includes commands for inserting a user into the `users` table and how to retrieve the hashed value of a user's email and first name.

---

## Database Setup

This document provides instructions for working with the MariaDB database, specifically for the `users` table.

### **1. Inserting a User into the `users` Table**

To insert a new user into the `users` table, use the following SQL command. Ensure that the `users` table has the columns `first_name`, `last_name`, `email`, `username`, and `password_hash`.

```sql
INSERT INTO users (first_name, last_name, email, username, password_hash)
VALUES ('John', 'Doe', 'johndoe@example.com', 'johndoe', SHA1('password123'));
```

### **2. Insert Multiple Users**

To insert multiple users at once, use the following command:

```sql
INSERT INTO users (first_name, last_name, email, username, password_hash)
VALUES
('Alice', 'Smith', 'alice@example.com', 'alicesmith', SHA1('alicepassword')),
('Bob', 'Johnson', 'bob@example.com', 'bobjohnson', SHA1('bobpassword'));
```

### **3. Retrieving the Hashed Value of a User**

To retrieve the hashed value of a user's email and first name, use the following SQL command. This example uses the `SHA1()` function to generate the hash.

```sql
SELECT SHA1(CONCAT(email, first_name)) AS hashed_value
FROM users
WHERE email = 'johndoe@example.com';
```

### **4. Example of Retrieving User Data**

To display all information for a specific user, you can run the following command:

```sql
SELECT * FROM users
WHERE username = 'johndoe';
```

---

### **Important Notes:**
- Ensure that passwords are hashed before storing them in the database for security purposes.



