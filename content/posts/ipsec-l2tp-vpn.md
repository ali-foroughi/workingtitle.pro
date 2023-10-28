---
title: "IPSEC/L2tp VPN"
date: 2020-06-04
draft: false
---
For a long time I was looking for a personal VPN solution. I was too lazy to work on setting up a VPN server from scratch so I had to try out many different options online. I tried OpenVPN for a while and used free online servers but that wasn’t good enough. Slow speeds and difficulty in connecting to some servers were the biggest issue.

I’ve tried using OpenVPN and configuring my own server, but the setup and installation process is a little bit too convoluted and I didn’t find it very user-friendly. 

## IPsec/L2TP

The best solution I’ve found has been <a href="https://github.com/hwdsl2/setup-ipsec-vpn">this IPSec/L2TP on github</a>. Thanks to hwdsl2 he saved me a lot of trouble. The setup processes on the server couldn’t be easier.

On the client side, you’ll have to do a one-time registry edit but that’s not too bad. The only downside I can think of is that it allows for only 1 connection per IP. So you can’t have multiple devices that share a public IP connect to the server. Other than that, it works like a charm. 
