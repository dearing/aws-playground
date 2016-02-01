/etc/nanorc:
  file.managed:
    - source: salt://common/nano/nanorc
    - mode: 0644
    - user: root
    - group: root
    - require: 
      - pkg: common_packages
