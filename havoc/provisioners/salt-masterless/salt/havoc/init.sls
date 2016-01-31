include:
  - havoc.install
  - havoc.config

havoc-service:
  service:
    - name: havoc
    - running
    - enable: True