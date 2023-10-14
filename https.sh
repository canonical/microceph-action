#!/usr/bin/bash

set -eux

usage() { echo "Usage: $0 ${FULL_PATH_TO haproxy.cfg.template}" 1>&2; exit 1; }

# We expect only one path: the haproxy.cfg.template full path
if [ $# -ne 1 ]; then
    usage
fi

sudo apt install -qq -y haproxy

IP="$(hostname -I | awk '{print $1}')"
CA="/etc/ssl/microceph.crt"

# The first option is the haproxy.cfg.template
cat "$1" > haproxy.cfg
echo "      server http_server1 ${IP}:80" >> haproxy.cfg
sudo rm /etc/haproxy/haproxy.cfg
sudo mv haproxy.cfg /etc/haproxy/haproxy.cfg

sudo openssl req \
    -x509 -sha256 -nodes \
    -days 365 \
    -newkey rsa:4096 \
    -subj "/CN=${IP}/O=microceph" \
    -keyout "${CA}.key" \
    -addext "subjectAltName = IP:${IP}" \
    -out "${CA}"

sudo systemctl restart haproxy

OUTPUT=$(pwd)/microceph.source
echo "export S3_SERVER_URL=https://${IP}" >> "${OUTPUT}"
echo "export S3_CA_BUNDLE_PATH=${CA}"     >> "${OUTPUT}"

set +e

