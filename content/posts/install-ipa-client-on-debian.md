---
title: "Install IPA Client on Debian 11"
date: 2023-04-05T16:27:43+03:30
draft: false
---

Couple of months ago I was setting up an IPA server for our infrastructure using CentOS. That went pretty smoothly but when I started joining clients to the IPA server, I quickly found out that the [IPA client package was missing from Debian 11](https://groups.google.com/g/linux.debian.project/c/0tZoaWBLtlg) repositories due to some bugs. This was clearly not ideal since most of our infrastructure runs on Debian 11.

My second solution was to use the [backports package](https://packages.debian.org/bullseye-backports/freeipa-client) from Debian, but that also failed on my machines due to some missing libraries that were present in Debian 10 but were removed from Debian 11.

Next, I tried to manually install and configure each service (SSSD, LDAP, NSS, Kerberos, etc) but to no avail. I feel like doing the configuration manually is prone to a lot of mistakes. So then I decided to write a bash script for it. Using the script everything is configured manually on the client machine. It needs to have access to the IPA server via ssh public key so it can copy some data from it such as CA certificate keys. It most definitely has many bugs, but it seems to be working for me now and I've joined 40+ Debian 11 nodes using this script.

I'm sharing the link here in the hopes that some poor soul stuck on this issue finds it and can use it.

https://github.com/ali-foroughi/ipa-client-install


If you do end up using it, please let me know how it went. 😅

Here's hoping that Debian finally gets their act together and fixes the package 🥂 