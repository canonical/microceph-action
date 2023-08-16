# Deploy Microceph S3 as GH Action

This action sets a single-node microceph with S3 and self-signed HTTPS support for testing with 1G net storage.

## Usage

```yaml
      - name: Setup microceph
        uses: phvalguima/microceph-action
        with:
          channel: 'latest/edge'
          devname: '/dev/sdi'
          accesskey: 'accesskey'
          secretkey: 'secretkey'
          bucket: 's3://testbucket'
```

Once ran, microceph will generate a file with all the details, named ```microceph.source```.
It will contain the following:

```
S3_SERVER_URL=https://<IP>
S3_ACCESS_KEY=...
S3_SECRET_KEY=...
S3_BUCKET=...
S3_CA_BUNDLE_PATH=<path>
```

Use the environment variables above for the next steps, for example:

```
$ s3cmd [--no-check-certificate] --host "${S3_SERVER_URL}" \
        --access_key="${S3_ACCESS_KEY}" \
        --ca-cert="${S3_CA_BUNDLE_PATH}" \
        --secret_key="${S3_SECRET_KEY}" ls
```
