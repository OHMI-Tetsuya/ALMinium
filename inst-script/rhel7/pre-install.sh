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
yum update -y ca-certificates

# 古いpassenger設定を削除する
#if [ "`ls /etc/httpd/conf.d/passenger.conf 2>/dev/null`" != "" \
#     -a "`grep snippet /etc/httpd/conf.d/passenger.conf 2>/dev/null`" = "" ]; then
#  rm -f /etc/httpd/conf.d/passenger.conf
#fi

# 必要なパッケージをインストール
yum install -y epel-release yum-utils
#curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo
yum install -y --nogpgcheck `grep -v "^#" inst-script/${OS}/packages.lst`

# set passenger-package available 
#ALM_PASSSENGER_PACKAGE_AVAILABLE=1

# for Jenkins installation
JENKINS_SYS=${OS}

# install ssl module
if [ "${ALM_ENABLE_SSL}" = "y" ]; then
    yum -y install mod_ssl
fi

# データベース起動および自動起動設定
if [ "${ALM_DB_SETUP}" = "y" -a "${ALM_USE_EXISTING_DB}" != "y" ]; then
  yum install -y mariadb-server
  service mariadb start
  systemctl enable mariadb
fi

# ruby
if [ "`which ruby`" == "" -o "`ruby --version | grep 2.0.`" != "" ]; then
#    rpm -Uvh "https://github.com/hansode/ruby-rpm/blob/master/6/x86_64/ruby-2.1.2-2.el6.x86_64.rpm?raw=true"
  source inst-script/${OS}/install-ruby.sh
fi

# git update
if [ "${GIT_UPDATE}" = "y" ]; then
  yum remove -y git
  #curl -s https://setup.ius.io/ | bash
  #yum install -y git2u
  source inst-script/git_build_install.sh
fi

