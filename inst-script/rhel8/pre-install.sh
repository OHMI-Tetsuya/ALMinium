#!/bin/bash

if [ "${USE_DISABLE_SECURITY}" = "" ]; then
  echo "*******************************************************"
  echo "  セキュリティの設定"
  echo "*******************************************************"
  echo "アプリケーションを動作させるために、ファイアフォールの設定とSELinuxの無効化を行います。"
  echo "nと答えると手動でセキュリティの設定が必要となります。分らない場合はYと答えてください。"
  echo 
  echo -n "アプリケーションを動作させるためにセキュリティの設定を行いますか?(Y/n)"
  read USE_DISABLE_SECURITY
fi
#sudo yum update -y ca-certificates
#sudo dnf update -y ca-certificates || fatal_error_exit ${BASH_SOURCE}

# モジュールのバージョンを設定
sudo dnf module reset -q -y mysql || fatal_error_exit ${BASH_SOURCE}
sudo dnf module enable -y mysql:8.0 || fatal_error_exit ${BASH_SOURCE}
sudo dnf module reset -q -y ruby || fatal_error_exit ${BASH_SOURCE}
sudo dnf module enable -y ruby:3.0 || fatal_error_exit ${BASH_SOURCE}
sudo dnf module reset -q -y subversion || fatal_error_exit ${BASH_SOURCE}
sudo dnf module enable -y subversion:1.14 || fatal_error_exit ${BASH_SOURCE}

# 古いpassenger設定を削除する
#if [ "`ls /etc/httpd/conf.d/passenger.conf 2>/dev/null`" != "" \
#     -a "`grep snippet /etc/httpd/conf.d/passenger.conf 2>/dev/null`" = "" ]; then
#  rm -f /etc/httpd/conf.d/passenger.conf
#fi

# 必要なパッケージをインストール
sudo dnf install -y epel-release || fatal_error_exit ${BASH_SOURCE}
sudo dnf upgrade -y || fatal_error_exit ${BASH_SOURCE}
#curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo
sudo dnf install -y `grep -v "^#" inst-script/${OS}/packages.lst` || fatal_error_exit ${BASH_SOURCE}

# set passenger-package available 
#ALM_PASSSENGER_PACKAGE_AVAILABLE=1


# for Jenkins installation
JENKINS_SYS=${OS}

# install ssl module
if [ "${ALM_ENABLE_SSL}" = "y" ]; then
    sudo dnf -y install mod_ssl || fatal_error_exit ${BASH_SOURCE}
fi

# データベース起動および自動起動設定
if [ "${ALM_DB_SETUP}" = "y" -a "${ALM_USE_EXISTING_DB}" != "y" ]; then
  sudo dnf install -y mysql-server || fatal_error_exit ${BASH_SOURCE}
  sudo systemctl start mysqld.service || fatal_error_exit ${BASH_SOURCE}
  sudo systemctl enable mysqld || fatal_error_exit ${BASH_SOURCE}
fi

# ruby
#if [ "`which ruby`" == "" ]; then
##    rpm -Uvh "https://github.com/hansode/ruby-rpm/blob/master/6/x86_64/ruby-2.1.2-2.el6.x86_64.rpm?raw=true"
#  source inst-script/${OS}/install-ruby.sh
#elif [ "`ruby --version | grep 2.0.`" != "" ]; then
#  source inst-script/${OS}/install-ruby.sh
#fi

# git update
if [ "${GIT_UPDATE}" = "y" ]; then
  sudo dnf remove -y git || fatal_error_exit ${BASH_SOURCE}
  sudo dnf install -y gcc curl-devel expat-devel openssl-devel || fatal_error_exit ${BASH_SOURCE}
  #curl -s https://setup.ius.io/ | bash
  #yum install -y git2u
  source inst-script/git_build_install.sh
fi
