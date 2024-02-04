create database if not exists `mydb`;

use mydb;

CREATE TABLE IF NOT EXISTS `users` (
    id int NOT NULL AUTO_INCREMENT,
    firstname VARCHAR(10) NOT NULL,
    lastname VARCHAR(10) NOT NULL,
    age INT NOT NULL,
    PRIMARY KEY(id));

