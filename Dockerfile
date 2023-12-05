FROM reg.zcore.local/ubuntu/ubuntu:22.04 as hugo
RUN apt-get update && apt-get install -y \
    hugo \
&& apt-get autoremove -y && apt-get autoclean && rm -rf /var/lib/apt/lists/*

COPY . /src
WORKDIR /src
RUN hugo -d public/

FROM reg.zcore.local/proxy_cache/nginx:latest
COPY --from=hugo /src/public/ /usr/share/nginx/html
