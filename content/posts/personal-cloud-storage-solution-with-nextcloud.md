---
title: "Personal Cloud Storage Solution With Nextcloud"
date: 2020-10-10
draft: false
---

Ever wanted to have your own personal cloud storage space? I did. After I noticed my (free) Google Drive space running out.

Googling “Personal cloud” brings up bunch of results, such as ownCloud that I tried to get started with but I found it unnecessarily complicated.

The next best choice for a personal cloud storage is NextCloud, which is a completely free and open-source solution for setting up your own cloud storage server. 

Here’s what you need to setup NextCloud as a personal cloud storage:
<ul>
<li>A Linux VPS, preferably running on Ubuntu 18.04 or Redhat 8. For this example I’m using CentOS 7 which is also fine.</li>
<li>A valid IP</li>
<li>Optional: DNS Server so you could set it up as a sub directory for your domain. For example: cloud.workingtitle.pro would be the address of your <li>server for the web interface.</li>
<li>MySQL</li>
<li>Apache</li>
<li>PHP</li>
</ul>

## Getting started with a personal cloud storage

Firstly download the installation file from NextCloud’s website. Link found here.

The first thing you need to do is to go ahead and update your server. You can do so via this command:
```
sudo yum update
```
Make sure that you have MySQL ready and have access for creating a database and giving permissions.

You should also have Apache installed. If you don’t, install it via this command:
```
yum install httpd
```

## yum install httpd

The next step is to install PHP on your server if you don’t already have it. To check if you have PHP installed or not run the following command:
```
php -v
```

If PHP is installed, you’ll get output showing the version, if its not your server will be confused.

NextCloud recommends PHP version 7.3 or 7.4. So if don’t have it, go ahead and install using the following commands.

First add the EPEL repository to your server:
```
yum install epel-release yum-utils -y
```
```
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
```
Now add PHP 7.4 to your repository:
```
yum-config-manager --enable remi-php74
```

And finally install PHP and some of its core modules:
```
yum install php php-common php-opcache php-mcrypt php-cli php-gd php-curl php-mysql -y
```
After this PHP should be setup and ready to go.

Now NextCloud requires bunch of different modules. The full list can be found here:
```
PHP module ctype
PHP module curl
PHP module dom
PHP module GD
PHP module hash (only on FreeBSD)
PHP module iconv
PHP module JSON
PHP module libxml (Linux package libxml2 must be >=2.7.0)
PHP module mbstring
PHP module openssl
PHP module posix
PHP module session
PHP module SimpleXML
PHP module XMLReader
PHP module XMLWriter
PHP module zip
PHP module zlib
PHP module memcached
PHP module imagick
```

All of these should be included in the source tar.gz file that we install later, but that wasn’t the case for me and I had to install some of these manually. 

<br>

## Apache configuration

Create a file named <code>nextcloud.conf</code> under the directory <code>/etc/httpd/conf.d/</code> and add the following lines to the file:
```
<VirtualHost *:80>
  DocumentRoot /var/www/nextcloud/
  ServerName  cloud.workingtitle.pro

  <Directory /var/www/nextcloud/>
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews

    <IfModule mod_dav.c>
      Dav off
    </IfModule>

  </Directory>
  ```

<code>DocumentRoot</code> is the path fo the NextCloud files and it’s up to you where you want to place it. Just create a directory of your choice and the download the installation files and extract them within that diectory. Then specify the path within this <code>nextcloud.conf</code> file.

You should also change the <code>ServerName</code> section to the host name you want to set for your server. This is where the DNS server part I talked about comes into play. If you don’t know how to setup a DNS server, you can check out <b>my previous post</b>. 

<br>

## Installing SSL

The next step is to setup SSL for your domain. If you don’t know how, you can check my other guide about <b>setting up SSL on NGINX</b>.

An easy and fast way is to use <a href="https://certbot.eff.org/">Certbot</a>. It helps you to setup a Let’s Encrypt SSL on your server that renews itself automatically. It’s very easy to install as it’s only a few clicks. It’s 2020, if you don’t have SSL then you should reevaluate your life as a system admin 🙂

<br>

## Installation Wizard

Now we’re getting to the final stages. After you have configured Apache and installed SSL, restart it to make sure everything is okay.
```
systemctl restart httpd
```

Open the URL in your browser to continue with the web installation.
```
http://localhost/nextcloud
```

Type in the Administrator username and password of your choice. Then click on storage and database option to enter the database info.

NextClould recommends to user MySQL as the database. So go on your server and and create a new database and user name and enter the information in the fields.

Using SQLite is not recommended as it’s only intended for testing and educational purposes and not be used in a production environment.

<br>

## Defining trusted domains

By default only the domain name that’s entered in the Apache configuration will be allowed to access NextCloud. If you want to add another domain or subdomain you will have to manually add it to the trusted domains list.

Open the config.php file. The syntax for the trusted domains is like this:
```
'trusted_domains' =>
  array (
   0 => 'localhost',
   1 => 'cloud.workingtitle.pro',
   2 => 'newDomain.workingtitle.pro',
   3 => '192.168.1.50',
),
```
With this configuration you can access Nextclould via localhost address, as well as the hostnames and the IP 192.168.1.50. You can add and subtract from this list as you wish.

We’re done now. Open up the URL in your browser and you should see the login page.

For further information regarding user creation and file sharing management, I suggest checking out the <a href="https://docs.nextcloud.com/server/20/admin_manual/index.html">Official documentation</a>.