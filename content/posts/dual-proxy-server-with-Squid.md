---
title: "Dual proxy server with Squid"
date: 2020-05-31
draft: false
---

Due to some internet restriction that I was experiencing in 2019 , I was forced to find a way to circumvent the disruption to the internet connection, so this is what I did using Squid proxy Server

I had a VPS set up ready to go inside the country, and I had another identical VPS set up in Germany. You’re going to need very little resource for this. A dual core CPU with 2GB of ram on the VPS should be plenty.

To have reliable internet connection, I had to set up a squid proxy server on the VPS located within the country. I, while using my connection through the ISP had no connection to any IPs outside the country, but the VPS which was located in a data center did. This allowed me to find a way to the outside.

After this, I set also set up another squid proxy on the server located in Germany. The goal was to connect these two proxy servers together. So I could connect to the proxy server inside the country, where it could forward my request to the other proxy server in Germany.

If you don’t know about Squid, you can read about it and download it <a href="http://www.squid-cache.org/">from their website</a>. It’s a fairly easy installation process.

After installing Squid on both servers, here’s what I did with the configuration on the first VPS (within the country).

## First Server configuration for squid proxy

The following is the configuration for the internal squid proxy server. Which is the server within the country that is easily accessible but has internet restrictions. 

```
#Remember to replace the IPs!
#0.0.0.0 is the first sever inside the country and 1.1.1.1 is the 2nd VPS located in Germany

acl local-servers dstdomain 0.0.0.0 
cache_peer 1.1.1.1 parent 1992 0 no-query default 
cache_peer_domain 1.1.1.1 !0.0.0.0
never_direct deny local-servers
never_direct allow all
```

Please remember to change the IPs mentioned here with your server IP. 0.0.0.0 is the first server (inside country) and 1.1.1.1 is the second server (outside the country).

The rest are just default configurations for Squid which you can read about in their documentation. You can add the following lines to the main configuration file.

```
# Example rule allowing access from your local networks.
# Adapt to list your (internal) IP networks from where browsing
# should be allowed
acl localnet src 10.0.0.0/8	# RFC1918 possible internal network
acl localnet src 172.16.0.0/12	# RFC1918 possible internal network
acl localnet src 192.168.0.0/16	# RFC1918 possible internal network
acl localnet src fc00::/7       # RFC 4193 local private network range
acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines



acl SSL_ports port 443
acl Safe_ports port 80		# http
acl Safe_ports port 21		# ftp
acl Safe_ports port 443		# https
acl Safe_ports port 70		# gopher
acl Safe_ports port 210		# wais
acl Safe_ports port 1025-65535	# unregistered ports
acl Safe_ports port 280		# http-mgmt
acl Safe_ports port 488		# gss-http
acl Safe_ports port 591		# filemaker
acl Safe_ports port 777		# multiling http
acl CONNECT method CONNECT
auth_param basic program /usr/lib64/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid Basic Authentication
auth_param basic credentialsttl 2 hours
acl auth_users proxy_auth REQUIRED
http_access allow auth_users

pinger_enable off
half_closed_clients off
quick_abort_min 0 KB
quick_abort_max 0 KB
quick_abort_pct 95
client_persistent_connections off
server_persistent_connections off
################

#
# Recommended minimum Access Permission configuration:
#
# Deny requests to certain unsafe ports
http_access deny !Safe_ports

# Deny CONNECT to other than secure SSL ports
http_access deny CONNECT !SSL_ports

# Only allow cachemgr access from localhost
http_access allow localhost manager
http_access deny manager

# We strongly recommend the following be uncommented to protect innocent
# web applications running on the proxy server who think the only
# one who can access services on "localhost" is a local user
#http_access deny to_localhost

#
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
#

# Example rule allowing access from your local networks.
# Adapt localnet in the ACL section to list your (internal) IP networks
# from where browsing should be allowed
http_access allow localnet
http_access allow localhost

# And finally deny all other access to this proxy
http_access deny all

# Squid normally listens to port 3128
http_port 8081

# Uncomment and adjust the following to add a disk cache directory.
#cache_dir ufs /var/spool/squid 100 16 256

# Leave coredumps in the first cache dir
coredump_dir /var/spool/squid

#
# Add any of your own refresh_pattern entries above these.
#
refresh_pattern ^ftp:		1440	20%	10080
refresh_pattern ^gopher:	1440	0%	1440
refresh_pattern -i (/cgi-bin/|\?) 0	0%	0
refresh_pattern .		0	20%	4320
```

## Second Server configuration

The configs for the second proxy server located outside the country is much easier. We just have to tell Squid to accept requests from our other server. You can add the following lines to the squid configuration:
```
acl child_proxy src 0.0.0.0/32
http_access allow child_proxy
```
0.0.0.0 is the IP of the first server.

After doing this you should be set. Check your connections and make sure all needed ports are open on your firewalls on both servers.
