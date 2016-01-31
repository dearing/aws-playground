pub-ssh-keys:
  cmd.script:
    - source: salt://common/rax/rackerkeys.sh
    - user: root
    - group: root
    - shell: /bin/bash