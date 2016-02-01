#!/bin/bash -x

yum clean expire-cache
yum -y update
yum -y upgrade
