#!/bin/bash

# non-interactive mode
export DEBIAN_FRONTEND=noninteractive

# package list update
sudo apt-get -qq update || fatal_error_exit ${BASH_SOURCE}
sudo apt-get install -y --no-install-recommends apt-utils || fatal_error_exit ${BASH_SOURCE}

# add passenger to APT repository
#####sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
#####sudo apt-get install -y --no-install-recommends ca-certificates
sudo apt-get install -y --allow-change-held-packages --no-install-recommends apt-transport-https || fatal_error_exit ${BASH_SOURCE}
#echo deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main > /etc/apt/sources.list.d/passenger.list
#chown root: /etc/apt/sources.list.d/passenger.list
## remove old passenger's info 
#if [ "`ls /etc/apache2/mods-available/passenger.load 2>/dev/null`" != "" \
#     -a ! -f /etc/apache2/mods-available/passenger.load ]; then
#  rm -f /etc/apache2/mods*/passenger.*
#fi
#  set passenger-package available
#ALM_PASSSENGER_PACKAGE_AVAILABLE=1

# ubuntu1804 use apparmor
APPARMOR_ENABLED=1

# for Jenkins installation
JENKINS_SYS=debian

# ruby
if [ "${RUBY_LOCAL_INSTALL}" = "y" -o "${RUBY_LOCAL_INSTALL}" = "Y" ]; then
  if [ "${RUBY_PKG_UNINSTALL}" = "y" ]; then
    sudo gem uninstall bundler || fatal_error_exit ${BASH_SOURCE}
    sudo apt-get -y purge ruby ruby-dev || fatal_error_exit ${BASH_SOURCE}
    sudo apt-get -y autoremove || fatal_error_exit ${BASH_SOURCE}
  fi

  # install build dependencies
  #sudo dnf install -y zlib zlib-devel gcc-c++ patch readline readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison curl sqlite-devel
  #sudo apt-get install -y gcc g++ make libssl-dev libreadline-dev zlib1g-dev || fatal_error_exit ${BASH_SOURCE}
  sudo apt-get install -y autoconf patch build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev || fatal_error_exit ${BASH_SOURCE}

  source inst-script/install-rbenv-ruby.sh
fi

# install APT packages
if [ "${GIT_UPDATE}" = "y" ]; then
  sudo add-apt-repository -y ppa:git-core/ppa || fatal_error_exit ${BASH_SOURCE}
fi
sudo apt-get -qq update || fatal_error_exit ${BASH_SOURCE}
sudo apt-get install -y --no-install-recommends `grep -v "^#" inst-script/${OS}/packages.lst` || fatal_error_exit ${BASH_SOURCE}

#####REALLY_GEM_UPDATE_SYSTEM=1 sudo gem update --system 2.7.10

# SSL
if [ "${ALM_ENABLE_SSL}" = "y" ]; then
    sudo apt-get -y --no-install-recommends install ssl-cert || fatal_error_exit ${BASH_SOURCE}
    sudo a2enmod ssl rewrite || fatal_error_exit ${BASH_SOURCE}
else
    sudo a2dismod ssl || fatal_error_exit ${BASH_SOURCE}
fi

# DB
if [ "${ALM_DB_SETUP}" = "y" -a "${ALM_USE_EXISTING_DB}" != "y" ]; then
  sudo apt-get install -y --no-install-recommends mysql-server || fatal_error_exit ${BASH_SOURCE}
  sudo systemctl start mysql.service || fatal_error_exit ${BASH_SOURCE}
fi
