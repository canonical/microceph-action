#!/usr/bin/bash

set -eux

usage() { echo "Usage: $0 [-c <snap-channel>] [-d <device-name>] [-a <access-key>] [-s <secret-key>] [-b <bucket-name>] [-z <disk-size>]" 1>&2; exit 1; }

CHANNEL=latest/edge
ACCESS_KEY=access_key
SECRET_KEY=secret_key
BUCKET_NAME=testbucket
DISK_SIZE=5G

while getopts ":c:d:a:s:b:z:" o; do
    case "${o}" in
        c)
            CHANNEL=${OPTARG}
            ;;
        a)
            ACCESS_KEY=${OPTARG}
            ;;
        s)
            SECRET_KEY=${OPTARG}
            ;;
        b)
            BUCKET_NAME=${OPTARG}
            ;;
        z)
            DISK_SIZE=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

function check_ceph_ok_or_exit () {
    i=0
    for i in {1..5}; do
        if sudo microceph.ceph status | grep HEALTH_OK; then
            break
        else
            sudo microceph.ceph status
            sleep 30
            sudo microceph.ceph health detail
        fi
    done
    if [ "$i" -eq 5 ]; then
        exit 1
    fi
}

sudo apt-get -qq -y update
sudo apt-get -qq -y install snapd s3cmd

sudo snap install microceph --channel="${CHANNEL}"

sudo snap connect microceph:hardware-observe
sudo snap connect microceph:block-devices
sudo snap restart microceph.daemon

sudo microceph cluster bootstrap

sleep 30s

# Set mon warn threshold to slightly more than mon_data_avail_crit
sudo microceph.ceph config set "mon.$(hostname)" mon_data_avail_warn 6
sudo microceph disk add loop,"${DISK_SIZE}",3

check_ceph_ok_or_exit


sudo microceph enable rgw
sleep 15s

sudo microceph.radosgw-admin user create --uid=test --display-name=test
sudo microceph.radosgw-admin key create --uid=test --key-type=s3 --access-key "${ACCESS_KEY}" --secret-key "${SECRET_KEY}"

s3cmd --host localhost \
      --host-bucket="localhost/%(bucket)" \
      --access_key="${ACCESS_KEY}" \
      --secret_key="${SECRET_KEY}" --no-ssl mb "s3://${BUCKET_NAME}"

check_ceph_ok_or_exit

OUTPUT="$(pwd)"/microceph.source
echo "S3_ACCESS_KEY=${ACCESS_KEY}" >  "${OUTPUT}"
{ echo "S3_SECRET_KEY=${SECRET_KEY}"; echo "S3_BUCKET=${BUCKET_NAME}"; echo "S3_REGION=default"; } >> "${OUTPUT}"

set +e
