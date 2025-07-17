CREATE DATABASE IF NOT EXISTS blogdb;
USE blogdb;

-- USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    username VARCHAR(255) PRIMARY KEY,
    fyp1 VARCHAR(255),
    fyp2 VARCHAR(255),
    fyp3 VARCHAR(255)
);

-- BLOGS TABLE
CREATE TABLE IF NOT EXISTS blogs (
    blog_name VARCHAR(255),
    author VARCHAR(255),
    publish_status BOOLEAN,
    category_order VARCHAR(255),
    read_count INT DEFAULT 0
);
