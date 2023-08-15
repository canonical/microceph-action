# microceph-action

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
