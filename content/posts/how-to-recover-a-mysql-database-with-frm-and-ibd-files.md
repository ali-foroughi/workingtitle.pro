---
title: "How to Recover a MySQL Database With frm and .ibd Files"
date: 2022-05-28
draft: false
---

In order to recover a MySQL database, you need to have access to the .frm and .ibd files. I won’t get into how to acquire them, but if you have them, you can follow these steps to recover your database. (at least partially)

<br>

## What you’ll need

- .frm and .ibd files related to your database
- A server running the same version of MySQL as the database you want to restore

<br>

## Recover database structure

First thing we need to do is recover the database structure by using <code>mysqlfrm</code>

[mysqlfrm](https://helpmanual.io/help/mysqlfrm/) is a utility use to read .frm files and create the database structure based on those files. Here’s the steps:

Run mysqlfrm under the diagnostic mode to get the table structure.
```
mysqlfrm --diagnostic TABLE_NAME.frm > TABLE_NAME.txt
```

This table will create the database structure (the mysql CREATE comands) and store them in a text file for reference. If you look into the txt file you’ll see an output like this:
```
CREATE TABLE `wp_users` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT, 
  `user_login` varchar(128) NOT NULL, 
  `user_pass` varchar(128) NOT NULL, 
  `user_nicename` varchar(128) NOT NULL, 
  `user_email` varchar(64) NOT NULL, 
  `user_url` varchar(128) NOT NULL, 
  `user_registered` datetime NOT NULL, 
  `user_activation_key` varchar(1020) NOT NULL, 
  `user_status` int(11) NOT NULL, 
  `display_name` varchar(1000) NOT NULL, 
PRIMARY KEY `PRIMARY` (`ID`),
KEY `user_login_key` (`user_login`),
KEY `user_nicename` (`user_nicename`),
KEY `user_email` (`user_email`)
) ENGINE=InnoDB
  ROW_FORMAT=compact;
```
<br>

## Create the database on MySQL

Log into your MySQL server and create the MySQL database where you want the files to be restored. Take note that your MySQL query for creating the database has to include the default character set and collate. Here’s how I made my database:
```
CREATE DATABASE my_database DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_general_ci;
```
<br>

## Create table and import the .ibd file

Now we need to create the table using the .frm file that we extracted. Select the database and run your CREATE command that was included in the <code>TABLE_NAME.txt</code>
```
mysql > USE my_database;
mysql > CREATE TABLE `wp_users` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT, 
  `user_login` varchar(128) NOT NULL, 
  `user_pass` varchar(128) NOT NULL, 
  `user_nicename` varchar(128) NOT NULL, 
  `user_email` varchar(64) NOT NULL, 
  `user_url` varchar(128) NOT NULL, 
  `user_registered` datetime NOT NULL, 
  `user_activation_key` varchar(1020) NOT NULL, 
  `user_status` int(11) NOT NULL, 
  `display_name` varchar(1000) NOT NULL, 
PRIMARY KEY `PRIMARY` (`ID`),
KEY `user_login_key` (`user_login`),
KEY `user_nicename` (`user_nicename`),
KEY `user_email` (`user_email`)
) ENGINE=InnoDB
  ROW_FORMAT=compact;
```
Now we need to drop the .ibd file that’s created with the above command and replace it with the .ibd file we already have.
```
ALTER TABLE table_name DISCARD TABLESPACE;
```

Copy your own .ibd file to the directory where the database resides. On an ubuntu/debian server that directory would be:
```
/var/lib/mysql
```
now we need to import the new .ibd file for the table we just created:
```
ALTER TABLE table_name IMPORT TABLESPACE;
```
You should see a message that the query was successfully executed.

Repeat the same steps for every single table. you could write a bash script to automatically run the same tasks for each table. 
<br>

## Export the restored database

After following the steps for each of the tables, your database should be back to its original state. (more or less)

There might be some data corruption, but you’ll likely get back most of the content.

Run the following command to export your MySQL database:
```
mysqldump my_database > database_name_export.sql
```