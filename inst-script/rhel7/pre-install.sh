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

sudo yum upgrade -y || fatal_error_exit ${BASH_SOURCE}
sudo yum update -y ca-certificates || fatal_error_exit ${BASH_SOURCE}

# git update
if [ "${GIT_UPDATE}" = "y" ]; then
  sudo yum remove -y git git-* || ${BASH_SOURCE}
  sudo yum -y install https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm || ${BASH_SOURCE}
  sudo yum -y install git || ${BASH_SOURCE}
fi

# 古いpassenger設定を削除する
#if [ "`ls /etc/httpd/conf.d/passenger.conf 2>/dev/null`" != "" \
#     -a "`grep snippet /etc/httpd/conf.d/passenger.conf 2>/dev/null`" = "" ]; then
#  rm -f /etc/httpd/conf.d/passenger.conf
#fi

# デフォルトのパッケージのgccのバージョンは古すぎてrubyとpassengerのビルドに失敗するので、11系のgcc開発環境をインストールする
sudo yum install -y centos-release-scl || fatal_error_exit ${BASH_SOURCE}
sudo yum install -y devtoolset-11 || fatal_error_exit ${BASH_SOURCE}
#rootだけ11系gcc開発環境を有効にする
sudo bash -c "echo \"source /opt/rh/devtoolset-11/enable\" >> /etc/profile" || fatal_error_exit ${BASH_SOURCE}
 
# ruby
if [ "${RUBY_LOCAL_INSTALL}" = "y" -o "${RUBY_LOCAL_INSTALL}" = "Y" ]; then
  if [ "${RUBY_PKG_UNINSTALL}" = "y" ]; then
    sudo gem uninstall bundler || fatal_error_exit ${BASH_SOURCE}
    sudo yum -y remove ruby ruby-dev || fatal_error_exit ${BASH_SOURCE}
  fi

  # install build dependencies
  #sudo yum install -y gcc patch bzip2 openssl-devel libffi-devel libyaml-devel readline-devel zlib-devel gdbm-devel ncurses-devel || fatal_error_exit ${BASH_SOURCE}
  sudo yum install -y patch bzip2 openssl-devel libffi-devel libyaml-devel readline-devel zlib-devel gdbm-devel ncurses-devel || fatal_error_exit ${BASH_SOURCE}
  source inst-script/install-rbenv-ruby.sh
fi

# 必要なパッケージをインストール
sudo yum remove -y mariadb-* || ${BASH_SOURCE}
sudo rm -rf /var/lib/mysql/
sudo yum install -y epel-release yum-utils || ${BASH_SOURCE}
sudo yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-11.noarch.rpm #|| ${BASH_SOURCE}
sudo yum-config-manager --disable mysql80-community || ${BASH_SOURCE}
sudo yum install -y `grep -v "^#" inst-script/${OS}/packages.lst` || ${BASH_SOURCE}
sudo yum install -y --enablerepo=mysql80-community mysql-community-client mysql-community-devel || ${BASH_SOURCE}
# set passenger-package available 
#ALM_PASSSENGER_PACKAGE_AVAILABLE=1

# for Jenkins installation
JENKINS_SYS=${OS}

# install ssl module
if [ "${ALM_ENABLE_SSL}" = "y" ]; then
  sudo yum -y install mod_ssl || ${BASH_SOURCE}
fi

# データベース起動および自動起動設定
if [ "${ALM_DB_SETUP}" = "y" -a "${ALM_USE_EXISTING_DB}" != "y" ]; then
  sudo yum install -y --enablerepo=mysql80-community mysql-community-server || ${BASH_SOURCE}
  sudo systemctl start mysqld.service || ${BASH_SOURCE}
  sudo systemctl enable mysqld.service || ${BASH_SOURCE}
  ALM_DB_INIT_ROOT_PASS=$(sudo grep -oP "(?<=A temporary password is generated for root@localhost: )\S+" /var/log/mysqld.log) || ${BASH_SOURCE}
  mysql -u root -p"${ALM_DB_INIT_ROOT_PASS}" --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${ALM_DB_ROOT_PASS}';SET GLOBAL validate_password.policy = LOW;SET GLOBAL validate_password.length = 4;SET GLOBAL validate_password.check_user_name = OFF;" || ${BASH_SOURCE}
fi

# ここでローカルユーザーに11系gcc開発環境を有効にする。そうしないとrubyのビルドに失敗する
source /etc/profile

