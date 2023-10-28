---
title: "Setting Up a DNS Server on CentOS From Scratch"
date: 2020-07-13
draft: false
---

Setting up a DNS server with BIND is not a very difficult process, but most of the guides and walk-through I’ve read on the subject tend to make it more complicated than it has to be, or that their information is very outdated. The results are a group of confused system admins who get stuck in an endless loop of troubleshooting their damn DNS server!

So my goal here is to help you set up your DNS server and get it running with minimal hassle.

<br>

## What you will need to start

<ul>
<li>A freshly-installed Linux server ready to go. In this example, I’m going to be using CentOS 7</li>
<li>A valid public IP address</li>
<li>A registered domain name, e.g workingtitle.pro. If you don’t already have a domain name, you can register one through <a href="https://www.godaddy.com/it-it">GoDaddy</a> or <a href="https://www.namecheap.com/">Namecheap</a>.</li>
</ul>

<br>

## Domain settings
The first thing you’ll need to do is to create DNS records in your domain control panel. Login into your domain registry panel and create the nameserver records as so:
```
ns1.yourdomain.com     IP: [your-server-ip]
ns2.yourdomain.com     IP: [your-server-ip]
```
<br>

## Installing BIND and initial configuration

The first step is to install BIND, which is the software that controls our DNS server. You can do so via this command:
```
yum -y install bind bind-utils
```

After the installation process is done, we’ll need to make our changes to the BIND configuration file in order to function correctly. In CentOS BIND is managed by a process called “named“. Open the configuration file with the text editor of your choice:
```
vim /etc/named.conf
```
The first section we need to change is this part:
```
listen-on port 53 { 127.0.0.1; };
listen-on-v6 port 53 { ::1; };
```
However as it stands, the nameserver is only responding to requests from the server itself. (127.0.0.1). Therefore, if any computer on the internet tries to reach this server it will be rejected. We will need to change the value to any as so: 
```
listen-on port 53 { any; };
listen-on-v6 port 53 { any; };
```

Next, we need to allow the nameserver to accept query requests from any IP and to reject recursion. If Recursive DNS is active on a server, it will try to respond to DNS queries for domains that are NOT within your namesever. So technically, someone could ask your server for the IP of www.google.com. Obviously your server is not the authority for that, so it’s standard practice to disable recursion.
Make these changes as so:

```
allow-query { any; };
recursion no;
```

In the next step we need to define zones for your domain. In the end of the /etc/named.conf file, add the following lines:
```
zone "workingtitle.pro" IN {

         type master;
         file "/var/named/workingtitle.pro.db";
};
```

Replace “workingtitle.pro” with your own domain name. This section tells the users that the zone for the domain “workingtitle.pro” exists on this sever and the details can be found at /var/named/workingtitle.pro.db.

That’s all the changes we need to make to the configuration file. The rest of the settings are optional and you can change them based on your need.

<br>

## Creating Zone files

The next step is to create zone files for your domains. The zone files contain the DNS records, showing where each resource is located.

Create the zone file for the domain by editing this file:
```
vim /var/named/workingtitle.pro.db
```

This is the same directory we defined in the previous step. Copy and paste the content blew into the file.
```
$TTL 14400
workingtitle.pro.   IN  SOA     ns1.workingtitle.pro. hostmaster.workingtitle.pro. (
                                                1001    ;Serial
                                                4H      ;Refresh
                                                15M     ;Retry
                                                1W      ;Expire
                                                1D      ;Minimum TTL
                                                )

;Name Server Information
workingtitle.pro.	14400	IN	NS      ns1.workingtitle.pro.
workingtitle.pro.	14400	IN      NS      ns2.workingtitle.pro.

;IP address of Name Server
ns1	IN	A       8.8.8.8	;replace with your server public IP address
ns2	IN	A	8.8.8.8	;replace with your server public IP address

;Mail exchanger
workingtitle.pro.	IN  	MX 	10	mail.workingtitle.pro.

;A - Record HostName To IP Address
workingtitle.pro.     IN  A       8.8.8.8 ;replace with your server public IP address
www	IN	A	8.8.8.8	;replace with your server public IP address
mail	IN	A	8.8.8.8	;replace with your server public IP address

;CNAME record
ftp     IN	CNAME        workingtitle.pro.
```

Let’s take a look at each section individually:

```
;Name Server Information
workingtitle.pro.	14400	IN	NS      ns1.workingtitle.pro.
workingtitle.pro.	14400	IN      NS      ns2.workingtitle.pro.
```

Here we’re defining our nameserver address so We’re essentially telling anyone who is querying our server that the nameservers for domain “workingtitle.pro” are “ns1.workingtitle.pro” and “ns2.workingtitle.pro”. You should obviously change this to your own domain name.

```
;IP address of Name Server
ns1	IN	A       8.8.8.8	;replace with your server public IP address
ns2	IN	A	8.8.8.8	;replace with your server public IP address
```
Now we need to define the IP address of our nameservers. Here you can see that the IP for “ns1” and “ns2” has been defined. Replace 8.8.8.8 with your server public IP.

<b>Important note</b>: It is strongly advised to use at least two different servers with different IPs for your nameservers. This is to provide redundancy in case one of the nameservers fails, but in the spirit of keeping things simple, I’ve only used one server with a single IP.
```
;A - Record HostName To IP Address
workingtitle.pro.     IN  A       8.8.8.8 ;replace with your server public IP address
www	IN	A	8.8.8.8	;replace with your server public IP address
mail	IN	A	8.8.8.8	;replace with your server public IP address

;CNAME record
ftp     IN	CNAME        workingtitle.pro.
```
In this section we can set the main DNS records such as the A record for the domain, the IP of the mail server and other services.

<br>

## Firewall configuration

We need to open port 53 on the server firewall in order to allow DNS traffic through. You can use the following command:
```
firewall-cmd --zone=external --permanent --add-port=53/udp
firewall-cmd --reload
```
If you’re not using <code>firewalld</code>, you can use the following command to open the port with <code>iptables</code>.
```
iptables -A INPUT -p udp --dport 53 -j ACCEPT
```
<br>

## Start the DNS service

The configuration is done! We can go ahead and start the DNS service:
```
systemctl enable named
systemctl start named
```