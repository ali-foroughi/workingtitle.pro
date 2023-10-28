---
title: "Simple squid proxy server with basic authentication"
date: 2020-08-01
draft: false
---

In previous posts I talked about setting up a double-proxy server using Squid. In this guide I’m gonna walk you through setting up a simple proxy server using Squid, and apply a simple authentication method.

The official <a href="http://www.squid-cache.org/">Squid</a> documentation on this issue is very vague and all over the place and I couldn’t find a good and straightforward guide for it.

So here we go.

<br>

## What you will need

<ul>
<li>A Linux server (VPS). In this example I’m using a CentOS 7 machine but the steps should generally be the same on different distributions.</li>
<li>A valid IP address</li>
</ul>

<br>

## Installing Squid

The first step is to install Squid on your machine. Use the following command on CentOS.

First update your repositories via this command:
```
sudo yum -y update
```
Then install squid:
```
yum -y install squid
```
Start squid and enable it for system startup:
```
csystemctl start squid
systemctl enable squid
```

<br>

## Squid configuration

### Create a User for Squid

The first thing you’ll need to do is to set up a username and password for connecting to the proxy server. The username information for Squid is stored in this file:
```
nano /etc/squid/passwd
```
Create a new user with this command:
```
sudo htpasswd /etc/squid/passwd [username-here]
```
After entering the command a prompt shows up for defining new password. Enter your password and make sure to save this password because you will need it.   

### Edit the configuration file

Now we need to make the changes to the main squid configuration file. Open the file with your favorite text editor:
```
nano /etc/squid/squid.conf
```
Leave the default configuration in place (you might need them later) but add the following lines to the beginning of the file:
```
auth_param basic program /usr/lib64/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid Basic Authentication
auth_param basic credentialsttl 2 hours
acl auth_users proxy_auth REQUIRED
http_access allow auth_users
```

<code>/usr/lib64/squid/basic_ncsa_auth</code> is the library we’re using for authentication and the accepted user list is found at <code>/etc/squid/passwd</code> which we defined a user for early on.

Next add the following line to configuration:
```
acl localnet src 0.0.0.0/8
```
This tells Squid to accept connections from any IP. (After authentication). I added this because I want to be able to connect to the server from any location.

Another important section is the port configuration. In my case, Squid only seemed to be listening on IPv6 which was not ideal. So in order to change it I had to edit this section:
```
http_port 3128
```
In order to let Squid know you want it to listen on IPv4 add the IP 0.0.0.0 in front of it. As so:
```
http_port 0.0.0.0:3128
```
After this, save the configuration file and restart Squid:
```
service squid restart
```
<br>

## Firewall configuration

If you have firewall on your server, you’ll have to open the port 3128.

Use the following command on CentOS:
```
sudo firewall-cmd --zone=external --permanent --add-port=3128/tcp
sudo firewall-cmd --zone=external --permanent --add-port=3128/udp
sudo firewall-cmd --reload
```
If you’re not using firewall-cmd, you’ll have to open the port using <code>iptables</code>.
```
sudo iptables -A INPUT -p tcp --dport 3128 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 3128 -j ACCEPT
service iptables save
```
And that’s all. Everything is set now. Restart Squid and you should be good to go. 
```
service squid restart
```
If you’re having trouble connecting, make sure to check the Squid logs at <code>/var/log/squid/</code>

If you have any questions you can leave a comment on this post or email me at admin@workingtitle.pro