#!/bin/sh
set -eu

: "${DOMAIN_NAME:?DOMAIN_NAME is required}"

# Validate the domain before inserting it into NGINX configuration.
case "$DOMAIN_NAME" in
    *[!a-zA-Z0-9.-]*)
        echo "Invalid domain name" >&2
        exit 1
        ;;
esac

sed -i "s/__DOMAIN_NAME__/${DOMAIN_NAME}/g" \
    /etc/nginx/conf.d/default.conf

mkdir -p /etc/nginx/ssl

if [ ! -f /etc/nginx/ssl/inception.crt ] || \
   [ ! -f /etc/nginx/ssl/inception.key ]; then

    echo "Generating development TLS certificate..."

    openssl req -x509 -nodes \
        -newkey rsa:2048 \
        -days 365 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/CN=${DOMAIN_NAME}" \
        -addext "subjectAltName=DNS:${DOMAIN_NAME}"
fi

chmod 600 /etc/nginx/ssl/inception.key

exec "$@"
