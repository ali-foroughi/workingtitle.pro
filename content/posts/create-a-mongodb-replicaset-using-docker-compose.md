---
title: "Create a MongoDB Replica Set Using Docker Compose"
date: 2023-04-15T14:27:25+03:30
draft: false
---

I've been trying to setup a Graylog multi-node cluster for testing purposes and for that I needed to create a mongoDB replica set. Using docker seemed like the most logical choice so here's how I did it using Docker Compose.

I created 3 MongoDB containers, exposed the relevant ports and started the `mongod` process using the `--replSet` option and then specifying my replica set name such as `rs01`. Then you create your volumes for each MongoDB container.

After that I use a bash script `rs-init.sh` (placed under the scripts folder at the root of project) to initiate the replica set on `mongo1` container. 

Finally we use a another bash script `StartReplicaSet.sh` to stop and start the containers using docker compose.

So here's my full docker compose file:
```
version: '3.8'

services:
  mongo1:
    container_name: mongo1
    image: mongo
    volumes:
      - ./scripts/rs-init.sh:/scripts/rs-init.sh
      - /opt/mongo1/:/data/db
    networks:
      - mongo-network
    ports:
      - 27017:27017
    depends_on:
      - mongo2
      - mongo3
    links:
      - mongo2
      - mongo3
    restart: always
    entrypoint: [ "/usr/bin/mongod", "--bind_ip_all", "--replSet", "rs01" ]

  mongo2:
    container_name: mongo2
    image: mongo
    volumes:
      - /opt/mongo2/:/data/db
    networks:
      - mongo-network
    ports:
      - 27018:27017
    restart: always
    entrypoint: [ "/usr/bin/mongod", "--bind_ip_all", "--replSet", "rs01" ]

  mongo3:
    container_name: mongo3
    image: mongo
    volumes:
      - /opt/mongo3/:/data/db
    networks:
      - mongo-network
    ports:
      - 27019:27017
    restart: always
    entrypoint: [ "/usr/bin/mongod", "--bind_ip_all", "--replSet", "rs01" ]

networks:
  mongo-network:
    name: mongo-network
    driver: bridge
```

`rs-init.sh`: This is the bash script which initiates the replica set:
```
DELAY=25

mongosh <<EOF
var config = {
    "_id": "rs01",
    "version": 1,
    "members": [
        {
            "_id": 1,
            "host": "mongo1:27017",
            "priority": 2
        },
        {
            "_id": 2,
            "host": "mongo2:27017",
            "priority": 1
        },
        {
            "_id": 3,
            "host": "mongo3:27017",
            "priority": 1
        }
    ]
};
rs.initiate(config, { force: true });
EOF

echo "====> Waiting for ${DELAY} seconds for replica set configuration to be applied"

sleep $DELAY
```

`StartReplicaSet.sh`: This is the final script that starts the replica set:
```
#!/bin/bash

DELAY=10

docker compose down
docker compose up -d

echo "====> Waiting for ${DELAY} seconds for containers to go up"
sleep $DELAY

docker exec mongo1 sh -c 'chmod +x /scripts/rs-init.sh'
docker exec mongo1 /scripts/rs-init.sh
```

Now let's walk through each step:

1. We start by executing the bash script `StartReplicaSet.sh` which first stops previous containers and then starts the containers using `docker compose`.
2. It then waits for containers to start and get ready by using sleep in seconds. (specified by the `DELAY` variable)
3. After the containers are up, we make the `rs-init.sh` script which is one mongo1 container executable and run it.
4. `rs-init.sh` on mongo1 then initiates the replica set, electing mongo1 as the primary since we've specified the priority

And that's pretty much it. The cluster should then be up and running. One last thing to note is that if you're using an older version of MongoDB you might have to change the command `mongosh` to `mongo`

