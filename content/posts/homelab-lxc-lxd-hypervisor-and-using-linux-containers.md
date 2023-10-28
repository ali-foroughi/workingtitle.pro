---
title: "Homelab: LXC/LXD Hypervisor and using Linux Containers"
date: 2021-01-03
draft: false
---

I’m planning to set up an entire network on a home server for testing and practice purposes, using Linux containers. I’m looking to setup the follow services (more might be added in the future): 

<ul>
<li>LXC/LXD host machine</li>
<li><a href="https://cobbler.github.io/">Cobbler</a> server (for automatic VM creation) or maybe <a href="https://www.proxmox.com/en/">Proxmox</a></li>
<li>DHCP</li>
<li>DNS</li>
<li>FTP and file storage</li>
<li>NFS share</li>
<li>Postgres database server</li>
<li>Apache web server</li>
<li>NGINX load balancing</li>
<li>LDAP server for authentication and access management</li>
<li>at least 10 clients running various Linux distributions</li>
<li>Mail server using <a href="https://www.exim.org/">Exim</a> (or <a href="http://www.postfix.org/">Postfix</a>)</li>
<li><a href="https://www.nagios.org/">Nagios</a> server for monitoring</li>
<li>Syslog server (<a href="https://www.elastic.co/kibana/">kibana</a> and <a href="https://www.elastic.co/logstash/">logstash</a>)</li>
</ul>

<br>

## Setting up LCX/LXD machine

The first thing we need to do for setting up this network is to have a host machine for our containers. For all the services I mentioned in the last part we will be using Linux containers instead of full virtual machines. Because this network is only for testing and practice purposes, we don’t need large resource. I’m setting up this network on a host machine with only 8 GB of ram and a modest Intel core i5 CPU. Nothing crazy.

Use <a href="https://linuxcontainers.org/lxd/getting-started-cli/">this</a> guide to setup and install LXD. It’s recommended to use Ubuntu or Debian as your host server in this case but you could technically use other distributions as well, but in this case since we’re going to be using Proxmox as well, we’re going with the recommended Ubuntu option.

## Creating a new LXD container

Using Linux containers is different from virtual machines because they can share resources among them such as kernel to reduce load on the host machine. (Check out <a href="https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/virtualization_tuning_and_optimization_guide/chap-ksm">KSM</a>). This is great for our use case because we will be spinning up a lot of containers so we can run all the services on a modest host machine.

The full guide on how to spin up and use LXD containers are in the official guide, but generally you can start up a container with a command like this:
```
lxc launch ubuntu:20.04 TestServer
```
ubuntu is the operating system we want and 20.04 is the version of the server.

If you want to see all the images available, you can run this command:
```
lxc image list images:
```

This command will show all the images available on official repository. Once you setup a new container, the image will be downloaded and stored locally.

You can search for all images of a specific distribution like so:
```
lxc image list images: debian
```
Most of the useful commands for LXD/LXC can be found here. 
Play around with different commands, create new containers, connect to them, start and stop them to get the hang of it.

In the next post, we’re going to set up a Proxmox service to control these containers in a easier fashion, but it’s important to familiarize yourself with how they work at a command-line level.