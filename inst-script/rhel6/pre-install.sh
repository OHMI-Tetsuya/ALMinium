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
if [ -f /etc/yum.repos.d/epel.repo ]; then
  CHK=`grep "enabled=1" /etc/yum.repos.d/epel.repo`
  if [ "${CHK}" = "" ]; then
    sed '1,/enabled=0/s/enabled=0/enabled=1/' /etc/yum.repos.d/epel.repo >/tmp/epel.repo
    mv -f /tmp/epel.repo /etc/yum.repos.d/epel.repo
  fi
else
  yum -y --nogpgcheck install wget
  EPEL_RPM_NAME="epel-release-6-8.noarch.rpm"
  rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/${EPEL_RPM_NAME}
fi
yum -y --nogpgcheck install `grep -v "^#" inst-script/${OS}/packages.lst`

# ImageMagick
yum -y --nogpgcheck install epel-release
yum -y remove ImageMagick ImageMagick-devel
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
yum --enablerepo=remi -y --nogpgcheck install ImageMagick6 ImageMagick6-devel

# for Jenkins installation
JENKINS_SYS=${OS}

CHK=`grep Amazon /etc/system-release`
if [ "${CHK}" != '' ]; then
  #ImageMagickインストール時に、設置済のため、コメントアウト。
  #rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
  yum  --enablerepo=remi -y --nogpgcheck install mysqlclient16
fi

if [ "${ALM_ENABLE_SSL}" = "y" ]; then
    yum -y install mod_ssl
fi

# db
if [ "${ALM_DB_SETUP}" = "y" -a "${ALM_USE_EXISTING_DB}" != "y" ]; then
  yum install -y mysql-server
  sed -i "s|log-error=/var/log/mysqld|log-error=/var/log/mysql/mysqld|" \
      /etc/my.cnf
  mkdir -p /var/log/mysql
  chkconfig --add mysqld
  chkconfig mysqld on
  service mysqld restart
fi

# ruby
#if [[ `which ruby` == "" || ! `ruby --version` =~  2\.1\. ]]; then
#    rpm -Uvh "https://github.com/hansode/ruby-rpm/blob/master/6/x86_64/ruby-2.1.2-2.el6.x86_64.rpm?raw=true"
#fi
source inst-script/${OS}/install-ruby.sh

# git update
if [ "${GIT_UPDATE}" = "y" ]; then
  yum remove -y git
  #curl -s https://setup.ius.io/ | bash
  #yum install -y git2u
  source inst-script/git_build_install.sh
fi
