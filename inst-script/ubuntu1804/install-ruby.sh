#!/bin/bash

# ruby
# if ruby is old, remove
if [ "`dpkg-query -l | grep ruby`" != "" ]; then
  echo -e -n "\nVersion $(ruby --version | cut -c 6-10)のrubyがインストールされています。削除して新しいバージョンをインストールします。"
  echo -e -n "インストールを中止する場合は、ctrl+cでスクリプトの実行を中断してください。"
  read CONTINUE
  sudo gem uninstall bundler || fatal_error_exit ${BASH_SOURCE}
  sudo apt-get -y purge ruby ruby-dev || fatal_error_exit ${BASH_SOURCE}
  sudo apt-get -y autoremove || fatal_error_exit ${BASH_SOURCE}
else
  echo -e -n "\nVersion ${ALM_LOCAL_INSTALL_RUBY_VERSION}のrubyをインストールします。"
  echo -e -n "インストールを中止する場合は、ctrl+cでスクリプトの実行を中断してください。"
  read CONTINUE
fi

# install build dependencies
#sudo dnf install -y zlib zlib-devel gcc-c++ patch readline readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison curl sqlite-devel
sudo apt-get install -y gcc g++ make libssl-dev libreadline-dev zlib1g-dev || fatal_error_exit ${BASH_SOURCE}

# clone and install rbenv environment
if [ "`which rbenv`" = "" ]; then
  pushd /opt

  sudo git clone https://github.com/sstephenson/rbenv.git || fatal_error_exit ${BASH_SOURCE}
  sudo git clone https://github.com/sstephenson/ruby-build.git /opt/rbenv/plugins/ruby-build || fatal_error_exit ${BASH_SOURCE}

  sudo bash -c "echo 'export RBENV_ROOT=/opt/rbenv' >> /etc/profile" || fatal_error_exit ${BASH_SOURCE}
  sudo bash -c 'echo '\''export PATH=${RBENV_ROOT}/bin:${PATH}'\'' >> /etc/profile' || fatal_error_exit ${BASH_SOURCE}
  sudo bash -c 'echo '\''eval "$(rbenv init -)"'\'' >> /etc/profile' || fatal_error_exit ${BASH_SOURCE}
  sudo bash -c "source /etc/profile" || fatal_error_exit ${BASH_SOURCE}

  export PATH=/opt/rbenv/bin:/opt/rbenv/shims:$PATH

  popd
fi

# install latest ruby
sudo bash -cl "rbenv install -s -v ${ALM_LOCAL_INSTALL_RUBY_VERSION}" || fatal_error_exit ${BASH_SOURCE}
sudo bash -cl "rbenv rehash" || fatal_error_exit ${BASH_SOURCE}

#sets the default ruby version that the shell will use
sudo bash -cl "rbenv global ${ALM_LOCAL_INSTALL_RUBY_VERSION}" || fatal_error_exit ${BASH_SOURCE}

# to disable generating of documents as that would take so much time
sudo bash -c 'echo "gem: --no-document" > /root/.gemrc' || fatal_error_exit ${BASH_SOURCE}

# install bundler
sudo bash -cl "gem install bundler" || fatal_error_exit ${BASH_SOURCE}

# must be executed everytime a gem has been installed in order for the ruby executable to run
sudo bash -cl "rbenv rehash" || fatal_error_exit ${BASH_SOURCE}
