havoc-binary:
  archive.extracted:
    - name: /opt/havoc/
    - source: https://github.com/dearing/havoc_server/releases/download/v0.1.0/havoc_server_linux_amd64.tar.gz
    - source_hash: md5=2663a247d1a066a083447a14b868bca1
    - archive_format: tar
    - tar_options: v
    - require:
      - user: havoc