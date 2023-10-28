---
title: "Install SSL on Adobe Connect"
date: 2020-07-07
draft: false
---

Adobe Connect is a software primarily used for online classes and web conferencing. Installing SSL on the Connect services such as application and meeting are essential so we’re going to look at how to install SSL on Adobe Connect.

I’m going to assume you already have Adobe Connect installed on your server. If not, you can you <a href="https://helpx.adobe.com/adobe-connect/installconfigure/install-connect-using-installer.html">this guide</a> to install it.

Now let’s start. Please note that this guide is for Adobe Connect version 9 or higher.

<b>Before you start:</b>

Make sure your SSL keys are ready. They should be in this format:
<ul>
<li>Your main certificate key in .pem format. You might have received two separate files from your CA but you can combine these two to make a single file.</li>
<li>Private key in .pem format.</li>
<li>Remember not to use passphrase on your SSL keys.</li>
</ul>

## Install Stunnel

Now you need to install stunnel. It’s a program that adds SSL/TLS functionality to your website. Firstly, install it from here: https://www.stunnel.org/downloads.html

Secondly, open stunnel.exe and follow the installation process. It’s better to install in the C:\Connect\stunnel directory so it will be in the same directory as Adobe Connect and easier to troubleshoot. 

## Stunnel configuration

Copy the code below to the stunnel.conf file located at C:\Connect\Stunnel\conf\ and remove all the previous code found in the file so we can add the new configuration. but before making any changes, make sure you make a copy of the stunnel.conf file. 
```
; Protocol version (all, SSLv2, SSLv3, TLSv1)
sslVersion = all
options = NO_SSLv2
options = NO_SSLv3
options = DONT_INSERT_EMPTY_FRAGMENTS
options = CIPHER_SERVER_PREFERENCE
renegotiation=no
fips = no
;Some performance tunings
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
TIMEOUTclose=0
; application server SSL / HTTPS
3[https-vip]
accept = 10.1.1.1:443
connect = 127.0.0.1:8443
cert = C:\Connect\stunnel\certs\public_certificate_app-server.pem
key = C:\Connect\stunnel\certs\private_key_app-server.key
;configure ciphers as per your requirement and client support.
;this should work for most:
ciphers = TLSv1+HIGH:!SSLv2:!aNULL:!eNULL:!3DES
```

Remember to replace 10.1.1.1 with your server IP and In the “cert” and “key” directories you have to specifies the location of the certificate file and the private key respectively. These are the same keys with the .pem format I mentioned at the start.

Now, we can check to see if the certificate is working correctly with our configurations before taking it live. Follow these steps:
<ul>
<li>Open Stunnel.exe located at /bin/ folder. After doing that an icon appears in the notification area.</li>
<li>Right-click the icon and select “check configuration”</li>
<li>If everything is working correctly you should see a message like this:
“2020.07.04 11:40:18 LOG5[main]: Configuration successful”</li> 
</ul>

As the result of configurations being correct, we can go ahead and set up Stunnel as a service so you don’t need to manually start it every time you reboot the server. 

<ul>
<li>Navigate to the /bin/ directory via Windows Command Line (CMD)</li>
<li>Type the following command: stunnel.exe -install</li>
<li>In the Windows Services menu a new services will be created named Stunnel TLS Wrapper. Make sure that it’s set to automatic.</li>
</ul>

## Custom.ini

After making the changes to the configuration file, open the custom.ini file located at c:\Connect\9.x\

Add the following lines to the end of custom.ini:
```
ADMIN_PROTOCOL=https://
SSL_ONLY=yes
```
## Server.xml
Find this file and open it: <i>C:\Connect\9.x\appserv\conf\server.xml</i>

You need to make two changes and <b>uncomment</b> certain sections. First uncomment this part:

```
<Connector port="8443" protocol="HTTP/1.1"
    executor="httpsThreadPool"
        enableLookups="false"
        acceptCount="250"
        connectionTimeout="20000"
        SSLEnabled="false"
        scheme="https"
        secure="true"
        proxyPort="443"
        URIEncoding="utf-8"/>
```
and then this:

```
<Executor name="httpsThreadPool"
    namePrefix="https-8443-"
    maxThreads="350"
    minSpareThreads="25"/>
```
And you’re done. You have followed all the steps to install ssl on Adobe Connect.
<ul>
<li>First, Restart all related services, Adobe Connect, Adobe Media and Stunnel wrapper</li>
<li>Make sure that port 443 is open on your firewall. If there is a need, write an additional rule to let the traffic through.</li>
<li>If after restarting the services Adobe Connect doesn’t start and you see a “Not Ready” error, try restarting your MySQL server. That helped me.</li>
<li>Note that this is a simple configuration for the Application only. You can find the full details in this <a href="https://blogs.adobe.com/connectsupport/files/2016/04/Connect-SSL-Guide.pdf">official guide</a>.</li>
</ul>