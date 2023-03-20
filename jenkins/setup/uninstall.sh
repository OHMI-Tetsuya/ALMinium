#!/bin/bash

if [ -f /usr/bin/yum ]; then
    sudo yum -y remove jenkins || fatal_error_exit ${BASH_SOURCE}
elif [ -f /usr/bin/apt-get ]; then
    sudo apt-get -y remove jenkins || fatal_error_exit ${BASH_SOURCE}
fi
sudo rm -fr /var/lib/jenkins || fatal_error_exit ${BASH_SOURCE}
sudo rm -fr ${ALM_LOG_DIR}/jenkins || fatal_error_exit ${BASH_SOURCE}
