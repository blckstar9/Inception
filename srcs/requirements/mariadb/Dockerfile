FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends mariadb-server && \
    rm -rf /var/lib/apt/lists/*

COPY conf/99-inception.cnf /etc/mysql/mariadb.conf.d/99-inception.cnf
COPY tools/init.sh /usr/local/bin/init-mariadb

RUN chmod +x /usr/local/bin/init-mariadb

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init-mariadb"]
