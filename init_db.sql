-- Drop the database if it exists
DROP DATABASE IF EXISTS accounts;

-- Create a new database
CREATE DATABASE accounts;

-- Drop user if it exists
DROP USER IF EXISTS 'admin'@'%';

-- Create user with password
CREATE USER 'admin'@'%' IDENTIFIED BY 'admin123';

-- Grant permissions on the new database
GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%';

-- Apply changes
FLUSH PRIVILEGES;