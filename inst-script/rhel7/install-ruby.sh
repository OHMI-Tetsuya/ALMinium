#!/bin/bash

# install build dependencies
sudo yum install -y git-core zlib zlib-devel gcc-c++ patch readline readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison curl sqlite-devel

# ruby
# if ruby is old, remove
if [ "`which ruby`" != "" ]; then
  if [ "`ruby -v | grep 2.0.`" != "" ]; then
    echo -n "Version 2.0のrubyがインストールされています。削除して新しいバージョンをインストールします。"
    echo -n "インストールを中止する場合は、ctrl+cでスクリプトの実行を中断してください。"
    read CONTINUE
    sudo  gem uninstall bundler
    sudo yum -y remove ruby ruby-devel ruby-irb ruby-libs rubygem-bigdecimal rubygem-io-console rubygem-json rubygem-psych rubygem-rdoc rubygems rubygem-nokogiri rubygem-rack rubygem-rake rubygem-rake-compiler
  fi
fi

# clone and install rbenv environment
if [ "`which rbenv`" = "" ]; then
  pushd /opt

  sudo git clone https://github.com/sstephenson/rbenv.git
  sudo git clone https://github.com/sstephenson/ruby-build.git /opt/rbenv/plugins/ruby-build

  sudo bash -c "echo 'export RBENV_ROOT=/opt/rbenv' >> /etc/profile"
  sudo bash -c 'echo '\''export PATH=${RBENV_ROOT}/bin:${PATH}'\'' >> /etc/profile'
  sudo bash -c 'echo '\''eval "$(rbenv init -)"'\'' >> /etc/profile'
  sudo bash -c "source /etc/profile"

  export PATH=/opt/rbenv/bin:/opt/rbenv/shims:$PATH

  popd
fi

# install latest ruby
RBVER=2.5.9
sudo bash -cl "rbenv install -s -v ${RBVER}"
sudo bash -cl "rbenv rehash"

#sets the default ruby version that the shell will use
sudo bash -cl "rbenv global ${RBVER}"

# to disable generating of documents as that would take so much time
echo "gem: --no-document" > ~/.gemrc

# install bundler
sudo bash -cl "gem install bundler"

# must be executed everytime a gem has been installed in order for the ruby executable to run
sudo bash -cl "rbenv rehash"
