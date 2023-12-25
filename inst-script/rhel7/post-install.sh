#!/bin/bash

###
# Problem: Cannot start Redmine
# Log: The application encountered the following error: You have already activated strscan 3.0.1, but your Gemfile requires strscan 3.0.4.
#        Since strscan is a default gem, you can either remove your dependency on it or try updating to a newer version of bundler that supports strscan as a default gem.
# Temporary solution: Force reinstall strscan
###
sudo bash -cl "${GEM} update strscan --no-document" || fatal_error_exit ${BASH_SOURCE}

# Redmine Perlモジュール（リポジトリ認証連携）設定
sudo mkdir -p /etc/httpd/Apache/Authn
sudo rm -f /etc/httpd/Apache/Authn/Redmine.pm
sudo ln -s ${ALM_INSTALL_DIR}/extra/svn/Redmine.pm /etc/httpd/Apache/Authn/Redmine.pm

#
# Apache configs
#
# passenger check
#passenger-config validate-install --auto --validate-apache2
# mod_passenger
#pushd ${ALM_INSTALL_DIR}
#bundle exec passenger-install-apache2-module --snippet > ${ALM_ETC_DIR}/passenger.conf
#bundle exec passenger-install-apache2-module --auto --apxs2-path='/usr/bin/apxs'
#ruby ${ALM_INSTALL_DIR}/vendor/bundle/ruby/2.5.0/gems/passenger-5.3.1/bin/passenger-install-apache2-module --apxs2-path='/usr/bin/apxs'
#popd
#ln -sf "${ALM_ETC_DIR}/passenger.conf" "${APACHE_CONF_DIR}/"

##set alminium config
#ln -sf "${ALM_ETC_DIR}/alminium.conf"  "${APACHE_CONF_DIR}/"

# セキュリティ無効化の設定
if [ ! "${USE_DISABLE_SECURITY}" = "n" ]; then
  echo "SELinuxを無効化します"
  sudo setenforce 0
  CHK=`grep SELINUX=enforcing /etc/selinux/config`
  if [ ! "${CHK}" = '' ]; then
    sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config 
    echo "SELinuxが無効化されました"
  fi

  # ファイアウォールの設定で80番(http)および443番(https)を許可
  sudo firewall-cmd --add-service=http --add-service=https --zone=public --permanent
  sudo firewall-cmd --reload
  sudo firewall-cmd --list-all
fi

# MariaDB設定
#CHK=`grep "character-set-server=utf8" /etc/my.cnf`
#if [ "${CHK}" = "" ]; then
#  sudo mv /etc/my.cnf /etc/my.cnf.org
#  sudo bash -c "cat /etc/my.cnf.org | sed -e \"s/\[mysqld_safe\]/character-set-server=utf8\n\n\[mysqld_safe\]/g\" > /etc/my.cnf"
#  sudo bash -c "echo -e \"\n[mysql]\ndefault-character-set=utf8\n\" >> /etc/my.cnf"
#fi

#chkconfig --add httpd
sudo chkconfig httpd on

