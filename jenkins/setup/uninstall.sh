#!/bin/bash

if [ -f /usr/bin/yum ]; then
    sudo yum -y remove jenkins
elif [ -f /usr/bin/apt-get ]; then
    sudo apt-get -y remove jenkins
fi
sudo rm -fr /var/lib/jenkins
