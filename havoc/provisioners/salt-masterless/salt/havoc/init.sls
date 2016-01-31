
havoc-binary:
  archive.extracted:
    - name: /opt/havoc/
    - source: https://github.com/dearing/havoc_server/releases/download/v0.1.0/havoc_server_linux_amd64.tar.gz
    - source_hash: md5=2663a247d1a066a083447a14b868bca1
    - archive_format: tar
    - tar_options: v
    - require:
      - user: havoc

/etc/profile.d/havoc:
  file.managed:
    - contents: "export PATH=$PATH:/opt/havoc/"

/etc/init.d/havoc:
  file.managed:
    - source: salt://havoc/systemv
    - mode: 0755
    - user: root
    - group: root

havoc:
  user.present:
    - createhome: true
    - system: true
    - shell: /bin/bash
    - home: /srv/havoc

havoc-service:
  service:
    - name: havoc
    - enable: True