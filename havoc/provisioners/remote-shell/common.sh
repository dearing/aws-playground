#!/bin/bash -x

curl -s https://raw.githubusercontent.com/rax-brazil/pub-ssh-keys/master/rackerkeys.sh | bash

yum clean expire-cache
yum -y update
yum -y upgrade
