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
