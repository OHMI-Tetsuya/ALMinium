#!/bin/bash
sudo systemctl stop httpd.service || fatal_error_exit ${BASH_SOURCE}
sudo systemctl start httpd.service || fatal_error_exit ${BASH_SOURCE}
