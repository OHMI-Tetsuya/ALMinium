#!/bin/bash

if [ "`hash -t ruby 2>&1`" == "/usr/local/bin/ruby" ]; then
  hash -d ruby || fatal_error_exit ${BASH_SOURCE}
fi

# clone and install rbenv environment
if [ "`sudo bash -cl \"which rbenv\"`" = "" ]; then
  pushd /opt

  sudo bash -cl "git clone https://github.com/sstephenson/rbenv.git" || fatal_error_exit ${BASH_SOURCE}
  sudo bash -cl "git clone https://github.com/sstephenson/ruby-build.git /opt/rbenv/plugins/ruby-build" || fatal_error_exit ${BASH_SOURCE}

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
