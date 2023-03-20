#!/bin/bash
# ネットワーク0のデバイス名

echo オペレーティングシステムをチェックします。

#IPアドレス確認用文字列
ETH0=${ETH0:-enp0s3}

# check OS
if [ "${OS}" = "" ]; then
  if [ -f /etc/redhat-release ]; then
    APACHE_USER=apache
    APACHE_CONF_DIR=/etc/httpd/conf.d
    APACHE_SITE_CONF_DIR=${APACHE_CONF_DIR}
    APACHE_LOG_DIR=httpd
    MYSQL_LOG_DIR=mysql
### not use ###    MYSQLD='systemctl mysqld.service'
    CHK=`grep PLATFORM_ID=\"platform:el9\" /etc/os-release`
    if [ "${CHK}" != '' ]; then
        OS='rhel9'
        OS_NAME=$(grep -oP '(?<=PRETTY_NAME=").*(?=")' /etc/os-release)
        if [ "${OS_NAME}" = '' ]; then
            OS_NAME="CentOS 9.x"
        fi
        echo "${OS_NAME} が検出されました。"
    fi
    CHK=`grep PLATFORM_ID=\"platform:el8\" /etc/os-release`
    if [ "${CHK}" != '' ]; then
        OS='rhel8'
        OS_NAME=$(grep -oP '(?<=PRETTY_NAME=").*(?=")' /etc/os-release)
        if [ "${OS_NAME}" = '' ]; then
            OS_NAME="CentOS 8.x"
        fi
        echo "${OS_NAME} が検出されました。"
    fi
    CHK=`egrep "CentOS Linux release 7" /etc/redhat-release`
    if [ "${CHK}" != '' ]; then
        OS='rhel7'
        echo "CentOS 7.x が検出されました。"
    fi
  elif [ -f /etc/lsb-release ]; then
    APACHE_USER=www-data
    APACHE_CONF_DIR=/etc/apache2/mods-enabled
    APACHE_SITE_CONF_DIR=/etc/apache2/sites-available
    APACHE_LOG_DIR=apache2
    MYSQL_LOG_DIR=mysql
    MYSQLD='/etc/init.d/mysql'
    if [ "`grep 18.04 /etc/lsb-release`" != "" ]; then
      OS='ubuntu1804'
      echo "18.04 が検出されました。"
    fi
    if [ "`grep 20.04 /etc/lsb-release`" != "" ]; then
      OS='ubuntu2004'
      echo "20.04 が検出されました。"
    fi
    if [ "`grep 22.04 /etc/lsb-release`" != "" ]; then
      OS='ubuntu2204'
      echo "22.04 が検出されました。"
    fi
  fi
fi
if [ "${OS}" = "" ]; then
  echo "サポートされていないOSです。"
  echo "現在サポートされいているOSは、"
  echo "  * Ubuntu 18.04/20.04/22.04"
  echo "  * RHEL 7/8/9"
  echo "です。処理を中止します。"
  exit 1
fi

