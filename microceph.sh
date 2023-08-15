#!/usr/bin/bash

set -eux

usage() { echo "Usage: $0 [-c <snap-channel>] [-d <device-name>] [-a <access-key>] [-s <secret-key>] [-b <bucket-name>]" 1>&2; exit 1; }

CHANNEL=latest/edge
DEVNAME=/dev/sdi
ACCESS_KEY=access_key
SECRET_KEY=secret_key
BUCKET_NAME=s3://testbucket

function parse_args () {
    while getopts ":c:d:a:s:b:" o; do
        case "${o}" in
            c)
                CHANNEL=${OPTARG}
                ;;
            d)
                DEVNAME=${OPTARG}
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
            *)
                usage
                ;;
        esac
    done
}

parse_args

sudo apt-get -qq -y update
sudo apt-get -qq -y install snapd s3cmd

sudo snap install microceph --channel="${CHANNEL}"

sudo snap connect microceph:hardware-observe
sudo snap connect microceph:block-devices
sudo snap restart microceph.daemon

sudo microceph cluster bootstrap
sleep 30s

for l in a b c; do
  loop_file="$(sudo mktemp -p /mnt XXXX.img)"
  sudo truncate -s 1G "${loop_file}"
  loop_dev="$(sudo losetup --show -f "${loop_file}")"
  minor="${loop_dev##/dev/loop}"
  sudo mknod -m 0660 "/dev/sdi${l}" b 7 "${minor}"
  sudo microceph disk add --wipe "${DEVNAME}${l}"
done


sudo microceph.ceph status


sudo microceph enable rgw
sleep 15s


sudo microceph.radosgw-admin user create --uid=test --display-name=test
sudo microceph.radosgw-admin key create --uid=test --key-type=s3 --access-key "${ACCESS_KEY}" --secret-key "${SECRET_KEY}"

s3cmd --host localhost --host-bucket="localhost/%(bucket)" --access_key="${ACCESS_KEY}" --secret_key="${SECRET_KEY}" --no-ssl mb "${BUCKET_NAME}"

OUTPUT="$(pwd)"/microceph.source
echo "S3_ACCESS_KEY=${ACCESS_KEY}" > "${OUTPUT}"
echo "S3_SECRET_KEY=${SECRET_KEY}" >> "${OUTPUT}"
echo "S3_BUCKET=${BUCKET_NAME}"    >> "${OUTPUT}"

set +e
