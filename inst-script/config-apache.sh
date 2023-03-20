#!/bin/bash
# setup apache
sudo mkdir -p $ALM_ETC_DIR || fatal_error_exit ${BASH_SOURCE}
for FILE in $(ls -F -I *.conf etc | grep -v /)
do
  sudo cp etc/${FILE} ${ALM_ETC_DIR}/ || fatal_error_exit ${BASH_SOURCE}
done

