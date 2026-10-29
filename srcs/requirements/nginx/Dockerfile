
FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        openssl \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f /etc/nginx/sites-enabled/default

COPY conf/default.conf /etc/nginx/conf.d/default.conf
COPY tools/start.sh /usr/local/bin/start-nginx

RUN chmod +x /usr/local/bin/start-nginx

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/start-nginx"]
CMD ["nginx", "-g", "daemon off;"]
