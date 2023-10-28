---
title: "Create a Highly Available Kubernetes Cluster From Scratch"
date: 2022-06-20
draft: false
---

In this guide we’re looking to create a highly available Kubernetes cluster with multiple control plane nodes, loadbalancers and worker nodes.

The architecture of this Kubernetes cluster ensures a good level of availability and reliability for use in a production environment, but it is by no means fail-safe.

I’ve followed the recommendations from Kubernetes documentations which you can find [here](https://kubernetes.io/docs/home/). All I’ve done is to present them in a curated manner. 

## What you’ll need

- 3 Virtual machines for master nodes  running Debian or CentOS  with at least 2 GB of RAM and 2 CPU cores
- 2 worker nodes running Debian or CentOs. It can be either VM’s or bare-metal servers. Use full bare metal servers if you have heavy workloads
- At least 2 virtual machines running Debian or CentOs for load balancing

<br>

## Architecture

![kuber-arch](https://workingtitle.pro/images/kuber-arch.png)

- 3 separate master nodes (control planes) for redundancy
- the master nodes are connected via loadbalancer
- we’ll have at least 2 load balancing instance where they negotiate a virtual IP between the instances
- worker nodes connect to the loadbalancer and the loadbalancer distributes request between control plane nodes

<br>

## Setting up the Load balancers

We’ll be using HA proxy and Keepalived for the load balancing solution. I’ve followed [this guide](https://github.com/kubernetes/kubeadm/blob/main/docs/ha-considerations.md#options-for-software-load-balancing) for reference.

- Install HAProxy and Keepalived on both load balancing server
```
 apt install haproxy
```

```
apt install keepalived
```

- Edit /etc/keepalived/keepalived.conf and make the configurations
```
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}

vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state ${STATE}
    interface ${INTERFACE}
    virtual_router_id ${ROUTER_ID}
    priority ${PRIORITY}
    authentication {
        auth_type PASS
        auth_pass ${AUTH_PASS}
    }

    virtual_ipaddress {
        ${APISERVER_VIP}
    }

    track_script {
        check_apiserver
    }

}
```

- Add the script for health checking <code>/etc/keepalived/check_apiserver.sh</code>
```
#!/bin/sh
errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl --silent --max-time 2 --insecure https://localhost:${APISERVER_DEST_PORT}/ -o /dev/null || errorExit "Error GET https://localhost:${APISERVER_DEST_PORT}/"

if ip addr | grep -q ${APISERVER_VIP}; then

    curl --silent --max-time 2 --insecure https://${APISERVER_VIP}:${APISERVER_DEST_PORT}/ -o /dev/null || errorExit "Error GET https://${APISERVER_VIP}:${APISERVER_DEST_PORT}/"

fi
```

- Edit <code>/etc/haproxy/haproxy.cfg</code> and make the configurations based on the guide
```
# /etc/haproxy/haproxy.cfg
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon
#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 1
    timeout http-request    10s
    timeout queue           20s
    timeout connect         5s
    timeout client          20s
    timeout server          20s
    timeout http-keep-alive 10s
    timeout check           10s
#---------------------------------------------------------------------
# apiserver frontend which proxys to the control plane nodes
#---------------------------------------------------------------------
frontend apiserver
    bind *:${APISERVER_DEST_PORT}
    mode tcp
    option tcplog
    default_backend apiserver
#---------------------------------------------------------------------
# round robin balancing for apiserver
#---------------------------------------------------------------------
backend apiserver
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance     roundrobin
        server ${HOST1_ID} ${HOST1_ADDRESS}:${APISERVER_SRC_PORT} check
```
- The configuration on both servers can be identical except two parts in the keepalived configuration:
```
state MASTER
```

```
state BACKUP
```

The <code>MASTER</code> state should be on the main load balancer node and the <code>BACKUP</code>  state should be used on all others. You can have many <code>BACKUP</code>  nodes with the same state. 
```
priority ${PRIORITY}
```

Should be <b>LOWER</b> on the <code>MASTER</code> server. For example you can configure priority 100 on the <code>MASTER</code> server, priority 101 on the first <code>BACKUP</code> server, priority 102 on the second <code>BACKUP</code> server and so on.
```
option httpchk GET /healthz
```

This option should probably be changed to /livez. Check your kube-apiserver configuration file and match it to this value.

- Once the configuration on both servers is done restart the services
```
service haproxy restart
```

```
service keepalived restart
```
<br>

## Setting up master nodes

<br>

### First master node (main control plane)

<b>IMPORTANT NOTE:</b>

On Debian machines, you need to edit <code>/etc/default/grub</code> and set <code>systemd.unified_cgroup_hierarchy=0</code> as the value for <code>GRUB_CMDLINE_LINUX_DEFAULT</code> as so:
```
GRUB_CMDLINE_LINUX_DEFAULT="systemd.unified_cgroup_hierarchy=0"
```
Then update grub:
```
update-grub
```
and reboot the server.

- <code>yum update</code> OR <code>apt update</code> && apt upgrade

- Disable SElinux (for CentOS)
```
nano  /etc/selinux/config
.
.
.
SELINUX=disabled
```
- Letting iptables see bridged traﬃc
```
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
```
```
sysctl --system
``` 

- Set all hostnames in <code>/etc/hosts</code> if you’re not using a DNS serve
- Turn off swap
```
swapoff -a
```

- Open /etc/fstab and comment out the section related to swap
- [Install Docker](https://docs.docker.com/engine/install/)
- [Install kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- Open ports with firewalld
```
sudo firewall-cmd --zone=public --permanent --add-port=6443/tcp
sudo firewall-cmd --zone=public --permanent --add-port=2379-2381/tcp
sudo firewall-cmd --zone=public --permanent --add-port=10250/tcp
sudo firewall-cmd --zone=public --permanent --add-port=10257/tcp
sudo firewall-cmd --reload
```
- Configure native cgroups driver
```
cat > /etc/docker/daemon.json <<EOF{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
```
- Then apply the changes
```
systemctl daemon-reload
```
```
systemctl restart docker
```
- Pull kubeadm images
```
kubeadm config images pull --kubernetes-version v1.24.0
```

You can specify the desired version with <code>--kubernetes-version</code>. It’s recommended for all nodes to have the same version so it’s better to manually pull the same version on each master node as to avoid confusion. 

- After successfully pulling the images, initialize the master node via this command: 
```
kubeadm init  --apiserver-advertise-address=CLUSTER-ENDPOINT --control-plane-endpoint=cluster-endpoint --pod-network-cidr=10.244.0.0/16 --upload-certs --kubernetes-version v1.24.0
```
<code>CLUSTER-ENDPOINT</code> should point to the virtual IP of the loadbalancer. You can define it in <code>/etc/hosts</code> if you’re not using a DNS server.

- Apply flannel for cluster networking
```
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```
- Check the status of pods via:
```
kubectl  get pods -A
```
Everything should be running normally.

- Save the output from the kubeadm init command so it can be used for starting other master and worker nodes

<br>

## Second and Third Master nodes 

- Follow all of the steps mentioned in the previous section and pull the kubeadm images with:
```
kubeadm config images pull --kubernetes-version v1.24.0
```
- Join the second and third master nodes to the cluster via the output from the first master node. 
```
Kubectl join … 
```

<br>

## Adding worker nodes to the cluster

- Login to your worker node(s)
- Follow the same steps from the master node installation and pull the kubeadm images with: 
```
kubeadm config images pull --kubernetes-version v1.24.0
```
- Open the following ports with iptables or other firewall
```
iptables -A INPUT -p tcp --dport 10250 -j ACCEPT
iptables -A INPUT -p tcp --dport 30000:35000 -j ACCEPT
iptables -A INPUT -p tcp --dport 10248 -j ACCEPT
iptables-save > /etc/iptables/rules.v4
```
- Make sure DNS names are configured in <code>/etc/hosts</code> and the nameservers are set in <code>/etc/resolv.conf</code>

- Use kubeadm join command with the token acquired from the first master node to join the server into the cluster

- Finally, log into one of your master node (control plane) and run the following command to see all the joined nodes:
```
kubectl get nodes -A
```

You should see an output of all your nodes. (master + worker nodes)

Hopefully this article helped you in learning how to create a highly available Kubernetes cluster.

## Resources

- [Create a highly available Kubernetes cluster](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/)
- [Creating clusters with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
- [Installing kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [kubelet configuration](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/)
- [Issues with coreDNS](https://stackoverflow.com/questions/52645473/coredns-fails-to-run-in-kubernetes-cluster)
- [edit KUBELET_NETWORK_ARGS](https://serverfault.com/questions/1055263/kube-apiserver-exits-while-control-plane-joining-the-ha-cluster)
- [Disable selinux](https://linuxize.com/post/how-to-disable-selinux-on-centos-7/)
- [Disable GPG checking](https://serverfault.com/questions/288648/disable-the-public-key-check-for-rpm-installation)
- [Define cgroups driver systemd](https://stackoverflow.com/questions/43794169/docker-change-cgroup-driver-to-systemd)
- [kube-schedular fails on debain](https://discuss.kubernetes.io/t/why-does-etcd-fail-with-debian-bullseye-kernel/19696)