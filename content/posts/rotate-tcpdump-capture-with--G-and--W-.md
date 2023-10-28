---
title: "Permission Denied Problem with Tcpdump rotation"
date: 2023-04-27T14:11:38+03:30
draft: false
---

I needed to start a `tcpdump` process which rotates the PCAP once every hour. Using the `-G` option we can specify the number of seconds the process should run before rotation (in my case its 3600), and using `-W` we can tell it how many PCAP files should be retained. So if I need the PCAPs of the last 2 days, I would use `-W 48` since I'm rotating them once every hour.

Here's my command:

```
tcpdump -G 3600 -W 48 -i ens1f1 -w /data/dp-pcap/srv12-ens1f1-%Y-%m-%d_%H.%M.%S.pcap
```

It's all pretty straightforward, and it *should* work. As you start the process, it works as expected but when its time to rotate the PCAP, it will throw a `permission denied` error and terminates the processes. So what happens?

When you first start capture, tcpdump starts the process with owner that you're logged in with (in my case root), but once its time for rotation, it tries to write the output file to the directory using `tcpdump` as the owner. Since it doesn't have access to your write directory, it fails.

Yeah...it's not fun to find out about this in a production environment where PCAPs are critical. 

So how to fix it? 

**Option 1**: Set world-write permissions to the directory you're saving the files to. (in my case /data/dp-pcap)

**Option 2**: Change the owner of the directory to `tcpdump`

I got mad so I did **option 3** which was `chmod 777 dp-pcap/`. Would not recommend.

