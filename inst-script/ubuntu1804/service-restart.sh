#!/bin/bash
sudo systemctl stop apache2.service || fatal_error_exit ${BASH_SOURCE}
sudo systemctl start apache2.service || fatal_error_exit ${BASH_SOURCE}
