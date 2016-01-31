#!/bin/bash -x

rpm --import https://repo.saltstack.com/yum/redhat/6/x86_64/latest/SALTSTACK-GPG-KEY.pub
# rpm --import https://repo.saltstack.com/yum/redhat/7/x86_64/latest/SALTSTACK-GPG-KEY.pub

tee /etc/yum.repos.d/saltstack.repo <<EOF
[saltstack-repo]
name=SaltStack repo for RHEL/CentOS \$releasever
baseurl=https://repo.saltstack.com/yum/redhat/\$releasever/\$basearch/latest
enabled=1
gpgcheck=1
gpgkey=https://repo.saltstack.com/yum/redhat/\$releasever/\$basearch/latest/SALTSTACK-GPG-KEY.pub
EOF

yum clean expire-cache
yum -y update
yum -y upgrade
yum -y install salt-minion

chkconfig salt-minion on
service salt-minion start