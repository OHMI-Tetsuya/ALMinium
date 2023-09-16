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
sudo dnf module reset -q -y subversion || fatal_error_exit ${BASH_SOURCE}
sudo dnf module enable -y subversion:1.14 || fatal_error_exit ${BASH_SOURCE}

# ruby
if [ "${RUBY_LOCAL_INSTALL}" = "y" -o "${RUBY_LOCAL_INSTALL}" = "Y" ]; then
  # install build dependencies
#  sudo dnf install -y zlib zlib-devel gcc-c++ patch readline readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison curl sqlite-devel || fatal_error_exit ${BASH_SOURCE}
#  sudo dnf install -y zlib zlib-devel gcc-c++ patch readline readline-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison curl sqlite-devel || fatal_error_exit ${BASH_SOURCE}
  sudo dnf install -y gcc patch bzip2 openssl-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel || fatal_error_exit ${BASH_SOURCE}
  if [ "`echo \"${OS_NAME}\" | grep \"MIRACLE LINUX\"`" != "" ]; then
    sudo dnf update miraclelinux-repos || fatal_error_exit ${BASH_SOURCE}
    sudo dnf config-manager --set-enabled 8-latest-PowerTools || fatal_error_exit ${BASH_SOURCE}
    sudo dnf upgrade -y || fatal_error_exit ${BASH_SOURCE}
    sudo dnf install -y libyaml-devel || fatal_error_exit ${BASH_SOURCE}
  else
    sudo dnf install -y --enablerepo=powertools libyaml-devel || fatal_error_exit ${BASH_SOURCE}
  fi
  source inst-script/install-rbenv-ruby.sh
elif [ "${RUBY_PKG_INSTALL}" = "y" -o "${RUBY_PKG_INSTALL}" = "Y" ]; then
  if [ "${DNF_MODULE_SETTING_RUBY}" != "n" -a "${DNF_MODULE_SETTING_RUBY}" != "N" ]; then
    sudo dnf module reset -q -y ruby || fatal_error_exit ${BASH_SOURCE}
    sudo dnf module enable -y ruby:${ALM_RHEL8_PKG_INSTALL_RUBY_VERSION} || fatal_error_exit ${BASH_SOURCE}
  fi
  sudo dnf install -y ruby ruby-devel || fatal_error_exit ${BASH_SOURCE}
fi

# 古いpassenger設定を削除する
#if [ "`ls /etc/httpd/conf.d/passenger.conf 2>/dev/null`" != "" \
#     -a "`grep snippet /etc/httpd/conf.d/passenger.conf 2>/dev/null`" = "" ]; then
#  rm -f /etc/httpd/conf.d/passenger.conf
#fi

# 必要なパッケージをインストール
if [ "`echo \"${OS_NAME}\" | grep \"MIRACLE LINUX\"`" != "" ]; then
  sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm || fatal_error_exit ${BASH_SOURCE}
else
  sudo dnf install -y epel-release || fatal_error_exit ${BASH_SOURCE}
fi

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
