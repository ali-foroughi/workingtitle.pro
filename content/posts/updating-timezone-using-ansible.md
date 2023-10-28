---
title: "Updating Timezone Using Ansible"
date: 2023-04-03T13:55:59+03:30
draft: false
---

Recently Iran has stopped observing day-light savings (DST) time, which has caused various problems for everyone in the IT field. All of our servers were showing the wrong time since the tzdata package wasn't updated. I wrote this Ansible playbook to upgrade everything in an instance.

This playbook is for upgrading the tzdata package on Debain-based OS, using APT package mananger.
If you don't need an HTTP proxy for APT, simply remove the tasks related to it.

```
- name: Upgrade tzdata package for correcting timezone
  hosts: all
  become: yes
  tasks:
    - name: Create a directory for apt proxy
      ansible.builtin.file:
        path: /etc/apt/apt.conf.d/
        state: directory
        mode: '0744'

    - name: Create a proxy file if it doesn't exist
      ansible.builtin.file:
        path: /etc/apt/apt.conf.d/10proxy
        state: touch
        mode: '0744'

    - name: Edit /etc/apt/apt.conf.d/10proxy and insert http proxy IP
      lineinfile:
        path: /etc/apt/apt.conf.d/10proxy
        state: present
        line: Acquire::http { Proxy "http://172.17.93.162:3142"; }

    - name: Edit /etc/apt/apt.conf.d/10proxy and insert https proxy IP
      lineinfile:
        path: /etc/apt/apt.conf.d/10proxy
        state: present
        line: Acquire::https { Proxy "http://172.17.93.162:3142"; }

    - name: Upgrade tzdata
      ansible.builtin.apt:
        name: tzdata
        state: latest
        update_cache: yes
        update_cache_retries: 2
        only_upgrade: true
```

**###UPDATE###**: 

So it turns out some services like Syslog need to be restarted so they can read the correct time from the system. If you're able to, I'd suggest to just go ahead and restart the server. Otherwise, you can just restart Syslog:

```
systemctl restart syslog.socket
```