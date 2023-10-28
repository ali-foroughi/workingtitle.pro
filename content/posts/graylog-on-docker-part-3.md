---
title: "Graylog on Docker — Part 3: Graylog! "
date: 2023-07-30T17:31:00+03:30
draft: false
---

Now that we have a working [Elasticsearch cluster](https://workingtitle.pro/posts/graylog-on-docker-part-1/) and a [MongoDB replica set](https://workingtitle.pro/posts/graylog-on-docker-part-2/), we can move to the final piece of the puzzle — the Graylog cluster!

We will deploy 3 Graylog containers, one of which be will denoted as "master", using the `is_master = true` parameter in the configuration file. The other two containers will be worker nodes and will have identical configurations.

Here's our master configuration file:
```
is_master = true
node_id_file = /usr/share/graylog/node-id
password_secret = YmojUZtpNEXM9c9ztbrCrfKEcYHhHj3RmRADpR7kYwHE2Tybg5fFWYAgdAsPvivJC2qkjCJonDqmnRiFeRsQM
root_password_sha2 = 4faeec746f8ea72b8d89c91c8122acb828432f8c145bff35c4f3466477d0ec6e
root_timezone = Asia/Tehran
http_bind_address = 0.0.0.0:9000
elasticsearch_hosts = http://es01.example.net:9201,http://es02.example.net:9202,http://es03.example.net:9203
rotation_strategy = count
elasticsearch_max_docs_per_index = 20000000
elasticsearch_max_number_of_indices = 20
retention_strategy = delete
elasticsearch_shards = 4
elasticsearch_replicas = 3
elasticsearch_index_prefix = graylog
allow_leading_wildcard_searches = false
allow_highlighting = false
elasticsearch_analyzer = standard
output_batch_size = 500
output_flush_interval = 1
output_fault_count_threshold = 5
output_fault_penalty_seconds = 30
processbuffer_processors = 5
outputbuffer_processors = 3
processor_wait_strategy = blocking
ring_size = 65536
inputbuffer_ring_size = 65536
inputbuffer_processors = 2
inputbuffer_wait_strategy = blocking
message_journal_enabled = true
lb_recognition_period_seconds = 3
mongodb_uri = mongodb://mongo-cluster:27017,mongo-cluster2:27018,mongo-cluster3:27019/graylog?replicaSet=dbrs
mongodb_max_connections = 1000
mongodb_threads_allowed_to_block_multiplier = 5
proxied_requests_thread_pool_size = 32
```

And this will be our slave configuration file, which is identical to master with the difference that `is_master` is set to `false`.
```
is_master = false
node_id_file = /usr/share/graylog/node-id
password_secret = YmojUZtpNEXM9c9ztbrCrfKEcYHhHj3RmRADpR7kYwHE2Tybg5fFWYAgdAsPvivJC2qkjCJonDqmnRiFeRsQM
root_password_sha2 = 4faeec746f8ea72b8d89c91c8122acb828432f8c145bff35c4f3466477d0ec6e
root_timezone = Asia/Tehran
http_bind_address = 0.0.0.0:9000
elasticsearch_hosts = http://es01.example.net:9201,http://es02.example.net:9202,http://es03.example.net:9203
rotation_strategy = count
elasticsearch_max_docs_per_index = 20000000
elasticsearch_max_number_of_indices = 20
retention_strategy = delete
elasticsearch_shards = 4
elasticsearch_replicas = 3
elasticsearch_index_prefix = graylog
allow_leading_wildcard_searches = false
allow_highlighting = false
elasticsearch_analyzer = standard
output_batch_size = 500
output_flush_interval = 1
output_fault_count_threshold = 5
output_fault_penalty_seconds = 30
processbuffer_processors = 5
outputbuffer_processors = 3
processor_wait_strategy = blocking
ring_size = 65536
inputbuffer_ring_size = 65536
inputbuffer_processors = 2
inputbuffer_wait_strategy = blocking
message_journal_enabled = true
lb_recognition_period_seconds = 3
mongodb_uri = mongodb://mongo-cluster:27017,mongo-cluster2:27018,mongo-cluster3:27019/graylog?replicaSet=dbrs
mongodb_max_connections = 1000
mongodb_threads_allowed_to_block_multiplier = 5
proxied_requests_thread_pool_size = 32
```


Then we have our final docker compose file:

```
version: "3.8"

services:
  graylog-1:
    container_name: graylog-1-master
    image: graylog:5.0.6    
    volumes: 
      - ./graylog-config/master/:/usr/share/graylog/data/config/
    networks:
      - my-overlay-2
    ports:
      - 9000:9000 # Graylog web interface and REST API
      - 1514:1514 # Syslog TCP
      - 1514:1514/udp # Syslog UDP
      - 12201:12201 # GELF TCP
      - 12201:12201/udp # GELF UDP
      - 5045:5044 #Logstash port
    extra_hosts:
      - "es01.example.net:172.17.93.170"
      - "es02.example.net:172.17.93.171"
      - "es03.example.net:172.17.93.172"
    deploy:
      restart_policy:
        condition: on-failure
      placement:
        constraints:
          - node.labels.type == master
      replicas: 1
    entrypoint: [ "/docker-entrypoint.sh" ]

  graylog-2:
    container_name: graylog-2
    image: graylog:5.0.6
    volumes:
      - /opt/graylog-config/slave/:/usr/share/graylog/data/config/
    networks:
      - my-overlay-2
    ports:
      - 9001:9000 # Graylog web interface and REST API
      - 1515:1514 # Syslog TCP
      - 1515:1514/udp # Syslog UDP
      - 12202:12201 # GELF TCP
      - 12202:12201/udp # GELF UDP
      - 5044:5044 #Logstash port
    extra_hosts: 
      - "es01.example.net:172.17.93.170" 
      - "es02.example.net:172.17.93.171"
      - "es03.example.net:172.17.93.172"
    deploy:
      restart_policy:
        condition: on-failure
      placement:
        constraints:
          - node.labels.type == worker-1
      replicas: 1
    entrypoint: [ "/docker-entrypoint.sh" ]

  graylog-3:
    container_name: graylog-3
    image: graylog:5.0.6
    volumes:
      - /opt/graylog-config/slave/:/usr/share/graylog/data/config/
    networks:
      - my-overlay-2
    ports:
      - 9002:9000 # Graylog web interface and REST API
      - 1516:1514 # Syslog TCP
      - 1516:1514/udp # Syslog UDP
      - 12203:12201 # GELF TCP
      - 12203:12201/udp # GELF UDP
      - 5046:5044 #Logstash port
    extra_hosts: 
      - "es01.example.net:172.17.93.170" 
      - "es02.example.net:172.17.93.171"
      - "es03.example.net:172.17.93.172"
    deploy:
      restart_policy:
        condition: on-failure
      placement:
        constraints:
          - node.labels.type == worker-2    
      replicas: 1
    entrypoint: [ "/docker-entrypoint.sh" ]
networks:
  my-overlay-2:
    external: true

```

Here's the breakdown: 

- we're setting up 3 instances of Graylog, one master and two slaves.
- The master node gets its own configuration file via volumes and the slaves get their own.
- We use placement constraints to place containers on specific nodes, just as we did for the Elasticsearch cluster and MongoDB cluster. This ensures we have the highest level of availability if one of the nodes in our Docker Swarm goes down. 
- We use `extra_hosts` to specify the IP address of the nodes where Graylog can access elasticsearch. The addresses specified such as `es01.example.net` is configured as the elasticsearch node in the Graylog configuration file mentioned before. 
- Please note that all of our containers in the cluster (Elastic, Mongo, Graylog) use a single shared overlay network (`my-overlay-2`) so they can access each other.
