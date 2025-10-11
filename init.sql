-- init.sql

-- Create database if it doesn't already exist
CREATE DATABASE IF NOT EXISTS webappdb;

-- Switch to that database
USE webappdb;

-- Ensure the correct user is created with mysql_native_password
CREATE USER IF NOT EXISTS 'webapp'@'%' IDENTIFIED WITH mysql_native_password BY 'webapppassword';
GRANT ALL PRIVILEGES ON webappdb.* TO 'webapp'@'%';
FLUSH PRIVILEGES;

-- Create the transactions table
CREATE TABLE IF NOT EXISTS transactions(
    id INT NOT NULL AUTO_INCREMENT,
    amount DECIMAL(10,2),
    description VARCHAR(100),
    PRIMARY KEY(id)
);

-- Seed data
INSERT INTO transactions (amount, description) VALUES
('400', 'groceries');
