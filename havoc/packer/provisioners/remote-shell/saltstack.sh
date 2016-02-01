#!/bin/bash -x

# manually boostrap salt with the develop branch and let packer continue, skipping the installation
curl -L https://raw.githubusercontent.com/saltstack/salt-bootstrap/develop/bootstrap-salt.sh | sudo sh -s
rm -Rfv /srv/*
