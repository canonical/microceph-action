#!/usr/bin/bash

set -eux

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
    -keyout "/etc/ssl/${CA}.key" \
    -out "${CA}"
#openssl req \
#    -out /tmp/cert.csr \
#    -newkey rsa:4096 -nodes \
#    -keyout "/etc/ssl/microceph.key" \
#    -subj "/CN=${IP}/O=microceph" \
#    -addext "subjectAltName=IP:${IP}"
#openssl x509 -req -sha256 \
#    -extfile <(printf "subjectAltName=IP:${IP}") \
#    -days 365 \
#    -CA example.com.crt \
#    -CAkey example.com.key \
#    -set_serial 0 \
#    -in /tmp/cert.csr \
#    -out "/etc/ssl/microceph.crt"

OUTPUT=$(pwd)/microceph.source
echo "S3_SERVER_URL=https://${IP}" >> "${OUTPUT}"
echo "S3_CA_BUNDLE_PATH=${CA}"     >> "${OUTPUT}"

set +e

