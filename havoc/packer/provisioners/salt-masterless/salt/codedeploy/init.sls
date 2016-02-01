cd-preq:
  pkg.installed:
    - pkgs:
      - wget
      - ruby

cd-install:
  cmd.script:
    - source: salt://codedeploy-preqs/install.rb
    - user: root
    - group: root
    - shell: /bin/bash

cd-service:
  service:
    - name: codedeploy-agent
    - running
    - enable: True