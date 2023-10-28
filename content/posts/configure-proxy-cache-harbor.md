---
title: "Configure Harbor proxy cache for pulling images from Docker Hub"
date: 2023-08-19T11:14:50+03:30
draft: false
---

Due to severe sanctions restrictions, I've been having lots of trouble pulling images from Docker Hub. A great method of getting around this issue is to setup proxy cache on Harbor image registry. It can pull images from Docker Hub and cache them so for the next use, you'll end up pulling from your local repo instead of Docker Hub.

In order to do this, I needed to upgrade Harbor to the latest version. You can do that by following the [official docs](https://goharbor.io/docs/2.8.0/administration/upgrade/).

After you've done that, you can follow these steps:

1. On the Harbor dashboard navigate to **Administration > Registries > New Endpoint**
2. Select **Docker Hub** as the provider, give it a name and then test your connection to Docker Hub.
![new-endpoint-harbor](https://workingtitle.pro/images/new-endpoint-harbor.png)

3. Click on **Test connection** to check your connection. In my case, I had to configure an HTTP proxy in `harbor.yaml` file since my server does not have direct access to internet. *(Side note to all my Iranian readers: Use "shecan" as your DNS)*

4. After saving, you should have a working endpoint like this:
![endpoint-configured-harbor](https://workingtitle.pro/images/endpoint-configured-harbor.png)

5. Navigate to **Projects > New Project** and create a project named `proxy_cache`. Make sure to enable the proxy cache option and point it to the registry you just created. As so:

![proxy-cache-project-harbor](https://workingtitle.pro/images/proxy-cache-project-harbor.png)


And we're done! 

Now when you want to pull an image, you should do so in this format:

```
docker pull yourRepoAddress.com/proxy_cache/<image_name>:<image_tag>
```

In my example, it looks like this:
```
docker pull reg.zcore.local/proxy_cache/nginx:latest
```

If the image is already present, it will download it from the cache. Otherwise, it will pull it from Docker Hub. It will also always check and if there is a new version available on Docker Hub, it will try to download that. 



