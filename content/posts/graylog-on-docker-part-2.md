---
title: "Graylog on Docker — Part 2: MongoDB  "
date: 2023-07-09T17:38:53+03:30
draft: false
---

Now that we've setup our Elasticsearch cluster in [part one](https://workingtitle.pro/posts/graylog-on-docker-part-1/), we can move to the second stage which is setting up a MongoDB replica set.


## Configure MongoDB replica set

On our master machine (docker swarm), we will be add a new docker compose which will be used for the MongoDB deployment.


### mongo.yaml
```
version: "3.8"

services:
  mongo-1:
    image: mongo
    volumes:
      - /data/mongo/mongo1:/data/db
    command: 'mongod --oplogSize 128 --replSet dbrs'
    networks:
      - my-overlay-2
    ports:
      - 27017:27017
    deploy:
      placement:
        constraints:
          - node.labels.type == master
      replicas: 1
      restart_policy:
        condition: on-failure
  mongo-2:
    image: mongo
    volumes:
      - /data/mongo/mongo2:/data/db
    command: 'mongod --oplogSize 128 --replSet dbrs'
    networks:
      - my-overlay-2
    ports:
      - 27018:27017
    deploy:
      placement:
        constraints:
          - node.labels.type == worker-1
      replicas: 1
      restart_policy:
        condition: on-failure
  mongo-3:
    image: mongo
    volumes:
      - /data/mongo/mongo3:/data/db
    command: 'mongod --oplogSize 128 --replSet dbrs'
    networks:
      - my-overlay-2
    ports:
      - 27019:27017
    deploy:
      placement:
        constraints:
          - node.labels.type == worker-2
      replicas: 1
      restart_policy:
        condition: on-failure
volumes:
  mongodb:
    driver: "local"
networks:
  my-overlay-2:
    external: true
```

Now let's walk through it:

- We create 3 containers `mongo-1`,`mongo-2` and `mongo-3`
- Each container is always placed on a different node using `constraints`. I've configured my master node with the `master` label, and each of the worker nodes with a `worker` label. 
- MongoDB files are stored under the `/data/mongo` directory on each node. I've used NFS to mount this directory on a different server for larger storage but you can manually create these directories or each node, or change them entirely based on your needs. 
- The containers use the same network `my-overlay-2` as the rest of the containers described on [Part 1](https://workingtitle.pro/posts/graylog-on-docker-part-1/). This is crucial since we need all the components of the Graylog cluster (Elasticsearch, MongoDB, Graylog) to talk to each other. 
- The command `mongod --oplogSize 128 --replSet dbrs` tells our mongo instances that we want to initiate a replica set called `dbrs`. You can change this to your desired name. 
- I've used different host ports for each container (`27017`, `27018`, `27019`) since initially I didn't plan to place each container on a different node. If you're planning to omit the constrains so the containers can be placed on any node, you should keep this port configuration. Otherwise, you can switch to `27017:27017` for all the containers. 


## Start the Stack

That's pretty much it. Once you've made the changes to the compose file, save it somewhere on the master node and run it:
```
docker stack deploy -c mongo.yaml mongo
```


## Initialize the replica set

Once your containers are up and running, you should check the logs to make sure everything is okay. You can do so by this command:

```
docker logs -f <container_name>
```

If everything is done correctly, you should see something like `waiting to Initialize ...` in the logs.  If that's the case, you need to run this command from a machine that has access to your cluster:

```
mongosh --host '172.17.93.171:27017' --eval 'rs.initiate({ _id: "dbrs", members: [{ _id: 0, host : "172.17.93.171:27017" }, { _id: 1, host : "172.17.93.172:27018" }, { _id: 2, host : "172.17.93.170:27019" }]})'
```

- You should have `mongosh` installed on the node that's running this.
- Replace the IPs with your docker swarm node IPs.
- If you've changed the replica set name in the docker-compose file, make sure to change it from `dbrs` to your name.

Once this command is executed, you should see a message regarding the successful replica set initialization.


And that's it! You now have a working MongoDB replica set on docker swarm! 🥳🥳🥳 

In the next post, we're going to finish up the cluster by deploying Graylog. 



