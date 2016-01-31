#!/bin/bash -x

yum install -y golang
mkdir -p /srv/http/
useradd www -m -r

# su - www
# cd $HOME
# echo "export GOPATH=$HOME/golang" >> $HOME/.bashrc
# echo "export PATH=$PATH:$GOPATH/bin" >> $HOME/.bashrc
