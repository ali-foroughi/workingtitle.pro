---
title: "Graylog Deflector Problem"
date: 2023-07-09T16:31:24+03:30
draft: false 
---


So I've been setting up and testing a [Graylog multi-node](https://workingtitle.pro/posts/graylog-on-docker-part-1/) setup, and I've come across an annoying problem. Sometimes for some unknown reason as Graylog starts, it creates an index called `graylog_deflector` which is *supposed* to point to the correct index; an alias of some sorts.

But as it happens, [Graylog sometimes messes this up](https://community.graylog.org/t/graylog-deflector-exists-as-an-indexer-and-is-not-an-alias/7413) and ends up creating an actual index called `graylog_deflector`. So when I would log into my Graylog UI, I'd see this error:

```
Elasticsearch exception [type=index_not_found_exception, reason=no such index []]
```

Graylog can't create the index needed so it starts to complain.

The solution is just to delete the `graylog_deflector`.

1. First, stop your Graylog server instance. 
2. Delete the index (replace the IP and port with your own)
```
curl -X DELETE "172.17.93.170:9201/graylog_deflector?pretty"
```
3. Start your Graylog server again.


Now when you log in, Graylog shouldn't complain about the index again. If your issue isn't solved, comment here and let me know.


