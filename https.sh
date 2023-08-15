#!/usr/bin/bash

set -e

sudo apt install -qq -y haproxy

IP="$(hostname -I | awk '{print $1}')"
CA="/etc/ssl/microceph.crt"

cat haproxy.cfg.template > haproxy.cfg
echo "      server http_server1 ${IP}:80" >> haproxy.cfg
sudo rm /etc/haproxy/haproxy.cfg
sudo mv haproxy.cfg /etc/haproxy/haproxy.cfg

sudo openssl req \
    -x509 -sha256 -nodes \
    -days 365 \
    -newkey rsa:4096 \
    -subj "/CN=${IP}/O=microceph" \
    -keyout "${CA}.key" \
    -out "${CA}"

sudo systemctl restart haproxy

OUTPUT=$(pwd)/microceph.source
echo "S3_SERVER_URL=https://${IP}" >> "${OUTPUT}"
echo "S3_CA_BUNDLE_PATH=${CA}"     >> "${OUTPUT}"

set +e

