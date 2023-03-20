#!/bin/bash

# gitのソースコードをダウンロードしインストールする
pushd ${ALM_SRC_DIR}/cache
wget https://www.kernel.org/pub/software/scm/git/git-${ALM_GIT_VERSION}.tar.gz || fatal_error_exit ${BASH_SOURCE}
tar xzvf git-${ALM_GIT_VERSION}.tar.gz
cd git-${ALM_GIT_VERSION}
make "-j`fgrep 'processor' /proc/cpuinfo | wc -l`" prefix=/usr/local all || fatal_error_exit ${BASH_SOURCE}
sudo make prefix=/usr/local install || fatal_error_exit ${BASH_SOURCE}
if [ "`hash -t git 2>&1`" == "/usr/bin/git" ]; then
  hash -d git
fi
echo "git has been updated to `git --version | cut -c 5-`" || fatal_error_exit ${BASH_SOURCE}
popd
