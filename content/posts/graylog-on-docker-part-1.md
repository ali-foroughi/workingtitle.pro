---
title: "Graylog on Docker — Part 1: Elasticsearch "
date: 2023-07-02T15:08:08+03:30
draft: false
---

My goal is to setup a highly-available Graylog instance using multiple containers on 3 Virtual Machines. 

Our setup needs the following:

  - 3 Linux VMs running the latest version of docker
  - Docker swarm configured & initiated on all servers (1 master, 2 workers)


What we're going to do is deploy 3 containers for each component of the Graylog ecosystem. Each one of the these containers will be placed on one of our 3 VMs, giving us a high level of availability and redundancy. 

- 3 Elasticsearch containers running as a elastic cluster
- 3 MongoDB containers working as a ReplicaSet
- 3 Graylog containers working in a master-worker system
- 3 HAProxy containers responsible for load balancing the requests to the graylog containers.


I've tried to follow the rough design described by Graylog [in their documentation](https://go2docs.graylog.org/5-0/setting_up_graylog/multi-node_setup.html), but I've taken some liberties with how I've approached it. 


Since Graylog has to be setup in a specific order (Elasticsearch 🠒 MongoDB 🠒 Graylog), we're going to start part 1 with the Elasticsearch setup. 


## Elasticsearch cluster on Docker


Keep in mind that before using this docker compose file, you should have already configured your Docker swarm nodes & setup its networking correctly so all the nodes can connect to each other.

### Containers 

This docker compose file starts three instances of Elasticsearch called `es01`, `es02` and `es03` and places them on different nodes in the swarm. Once the containers are created, it initiates the elasticsearch cluster called `es-docker-cluster`. The value for `discovery.seed_hosts` should always point to other containers in the cluster. 

### Volumes

I've setup NFS storage on each of the VMs and mounted it to `/data/elastic/`. In this directory there are 3 subdirectories for each of the elasticsearch instances, so we have:
  - /data/elastic/es01
  - /data/elastic/es02
  - /data/elastic/es03

You should configure NFS or GlusterFS and specify your volumes for each container. 


### Networking
The network I've used is a simple `overlay` network which should be setup and configured before the cluster initialization. The `overlay` network is part of Docker Swarm and it allows different nodes in the Swarm to talk to each other. 


### Constraints

Using `node.role` constraint, we can specify exactly where the container should be placed. This is necessary for ensuring maximum availability and redundancy in case of one or two of the VMs crashing or going offline. 


## Starting the Elasticsearch cluster

Once everything is setup, copy the docker compose file below to a directory on your Docker Swarm master node and then start the cluster using this command:

```
docker stack deploy -c elasticsearch.yaml elastic
```


## elasticsearch.yaml

```
version: "3.8"
services:
  es01:
    image: elasticsearch:7.5.2
    container_name: es01
    environment:
      - node.name=es01
      - cluster.name=es-docker-cluster
      - discovery.seed_hosts=es02,es03
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - /data/elastic/es01:/usr/share/elasticsearch/data
    ports:
      - 9201:9200
    networks:
      - my-overlay-2
    deploy:
      placement:
        constraints: [node.role == manager]

  es02:
    image: elasticsearch:7.5.2
    container_name: es02
    environment:
      - node.name=es02
      - cluster.name=es-docker-cluster
      - discovery.seed_hosts=es01,es03
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - /data/elastic/es02:/usr/share/elasticsearch/data
    ports:
      - 9202:9200
    networks:
      - my-overlay-2
    deploy:
      placement:
        constraints: [node.role == worker]

  es03:
    image: elasticsearch:7.5.2
    container_name: es03
    environment:
      - node.name=es03
      - cluster.name=es-docker-cluster
      - discovery.seed_hosts=es01,es02
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - /data/elastic/es03:/usr/share/elasticsearch/data
    ports:
      - 9203:9200
    networks:
      - my-overlay-2
    deploy:
      placement:
        constraints: [node.role == worker]


networks:
  my-overlay-2:
    external: true

```

In [Part 2](https://workingtitle.pro/posts/graylog-on-docker-part-2/), we're going to be deploying a MongoDB replica set on Docker Swarm. 