---
title: "Install and Configure SSL on Nginx"
date: 2020-06-15
draft: false
---

NGINX is web server, reverse proxy and caching tool that is relatively new compared to Apache. It’s gaining popularity around the world due to its applications. Because of its load-balancing feature, it is widely used in websites with heavy traffic, the best example of which is YouTube. In this guide we’re going to look at how to install ssl on nginx

I’ll walk you through installing an SSL certificate on Nginx. Its a fairly easy process even if you have had no prior experience with Nginx.

I am going to assume you already have a valid SSL certificate, ready for installation. You can purchase a certificate from a variety of different sources such as Digicert or Comodo, but I would personally recommend using <a href="https://letsencrypt.org/">Let’s Encrypt<a/> which is a non-profit SSL CA backed by the Linux Foundation.

The first step is to log into your sever via ssh:
```
ssh root@[your-server-IP]
```
Navigate to the Nginx directory:
```
cd /etc/nginx/sites-available
```


## Editing virtual host configs

There should be a virtual host configuration file for your website under <i>sites-available/example.com.</i> Open the the file via a text editor. It should look like this:
```
server {
        listen 80;
        listen [::]:80;

        server_name your.domain.com;
        access_log /var/log/nginx/nginx.vhost.access.log;
        error_log /var/log/nginx/nginx.vhost.error.log;
        location / {
        root   /home/www/public_html/your.domain.com/public/;
        index  index.html;
        }
}
```

As you can see, Nginx is currently listening on port 80 which means your website is only using HTTP. In order to access the website with HTTPS, you need to create another server block. Copy the entire block and paste it below.

After copying the block, add the following lines to the new block: 
```
listen   443;

ssl    on;
ssl_certificate    /etc/ssl/your_domain_name.pem; (or bundle.crt)
ssl_certificate_key    /etc/ssl/your_domain_name.key;
```
This configuration tells Nginx to listen on port 443 (SSL) and it specifies the directories for your SSL keys.

“ssl_certificate” is the directory for your main SSL key or the bundle.

“ssl_certificate_key” is the directory for the private key.

Make sure that the paths specified are correct and your keys are places in the those directories. Of course you can change to any other directory and update the configuration file accordingly.

In the end, your configuration file should look something like this:
```
server {
        listen 80;
        listen [::]:80;

        server_name your.domain.com;
        access_log /var/log/nginx/nginx.vhost.access.log;
        error_log /var/log/nginx/nginx.vhost.error.log;
        location / {
        root   /home/www/public_html/your.domain.com/public/;
        index  index.html;
        }
}

server {
        listen 443;
        listen [::]:443;

        ssl    on;
        ssl_certificate    /etc/ssl/your_domain_name.pem; (or bundle.crt)
        ssl_certificate_key    /etc/ssl/your_domain_name.key;

        server_name your.domain.com;
        access_log /var/log/nginx/nginx.vhost.access.log;
        error_log /var/log/nginx/nginx.vhost.error.log;
        location / {
        root   /home/www/public_html/your.domain.com/public/;
        index  index.html;
        }
}
```

## Check syntax

As you can see, with this configuration, your website is accessible through both port 80 and 443. In case you want your website to be available ONLY through HTTPS , you can remove the block with port 80, but that’s generally not recommended.

Now make sure that port 443 is open on your firewall. Then run this command to check Nginx syntax and configuration:

```
nginx -t
```

If it’s successful, then go ahead and restart Nginx for the changes to take effect.

```
service nginx restart
```

And that’s it. you’re pretty much done. We have learned how to install ssl on nginx. The website should be accessible through HTTPS.

If you would like to learn more about SSL/TLS in general, you can <a href="https://workingtitle.pro/index.php/2020/06/23/whats-the-difference-between-ssl-and-tls/">read</a> this. 