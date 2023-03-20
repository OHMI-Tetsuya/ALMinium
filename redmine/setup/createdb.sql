CREATE DATABASE alminium CHARACTER SET utf8mb4;
CREATE USER 'alminium'@'localhost' IDENTIFIED BY 'alminium';
GRANT ALL PRIVILEGES ON alminium.* TO 'alminium'@'localhost';
FLUSH PRIVILEGES;
