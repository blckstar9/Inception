#!/bin/sh
set -eu

: "${DOMAIN_NAME:?DOMAIN_NAME is required}"

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
