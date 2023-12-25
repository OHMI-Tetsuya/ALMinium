#!/bin/bash
############################################################
# Smart installer for ALMinium.
# 第1引数：データベースホスト名
# 第2引数：データベース管理者パスワード
############################################################
ALM_SRC_DIR=${ALM_SRC_DIR:-$(cd $(dirname $0);pwd)}
ALM_ETC_DIR=${ALM_ETC_DIR:-/etc/opt/alminium}
ALM_VAR_DIR=${ALM_VAR_DIR:-/var/opt/alminium}
ALM_INSTALL_DIR=${ALM_INSTALL_DIR:-/opt/alminium}
ALM_LOG_DIR=${ALM_LOG_DIR:-/var/log/alminium}

ALM_ENABLE_AUTO_BACKUP=${ALM_ENABLE_AUTO_BACKUP:-y}
ALM_GIT_MIN_VERSION=${ALM_GIT_MIN_VERSION:-2.39.3}
ALM_GIT_MIN_VERSION_NUM=${ALM_GIT_MIN_VERSION_NUM:-`echo ${ALM_GIT_MIN_VERSION} | (IFS=. read -r major minor build revision; printf "%2d%02d%02d%02d" ${major:-0} ${minor:-0} ${build:-0} ${revision:-0})`}
ALM_LOCAL_INSTALL_GIT_VERSION=${ALM_LOCAL_INSTALL_GIT_VERSION:-2.43.0}
ALM_GIT_AUTO_UPGRADE=${ALM_GIT_AUTO_UPGRADE:-N}
ALM_DB_SETUP=${ALM_DB_SETUP:-y}
ALM_DB_HOST=${1:-$ALM_DB_HOST}
ALM_DB_ROOT_PASS=${2:-$ALM_DB_ROOT_PASS}
ALM_RUBY_GE_VERSION=${ALM_RUBY_GE_VERSION:-2.7.0}
ALM_RUBY_GE_VER_NUM=${ALM_RUBY_GE_VER_NUM:-`echo ${ALM_RUBY_GE_VERSION} | (IFS=. read -r major minor build; printf "%2d%02d%02d" ${major:-0} ${minor:-0} ${build:-0})`}
ALM_RUBY_LT_VERSION=${ALM_RUBY_LT_VERSION:-3.2.0}
ALM_RUBY_LT_VER_NUM=${ALM_RUBY_LT_VER_NUM:-`echo ${ALM_RUBY_LT_VERSION} | (IFS=. read -r major minor build; printf "%2d%02d%02d" ${major:-0} ${minor:-0} ${build:-0})`}
ALM_LOCAL_INSTALL_RUBY_VERSION=${ALM_LOCAL_INSTALL_RUBY_VERSION:-3.0.6}
ALM_LOCAL_INSTALL_RUBY_VER_NUM=${ALM_LOCAL_INSTALL_RUBY_VER_NUM:-`echo ${ALM_LOCAL_INSTALL_RUBY_VERSION} | (IFS=. read -r major minor build; printf "%2d%02d%02d" ${major:-0} ${minor:-0} ${build:-0})`}
ALM_RHEL8_PKG_INSTALL_RUBY_VERSION=${ALM_RHEL8_PKG_INSTALL_RUBY_VERSION:-3.0}

RAILS_ENV=production

# move to sources directry
cd ${ALM_SRC_DIR}

RM_VER=${RM_VER:-`cat RM_VERSION`}
RM_ARC=https://github.com/redmine/redmine/archive/${RM_VER}.tar.gz

PATH=/usr/local/bin:${PATH}

# include functions
source inst-script/functions.sh

# check memory size
source inst-script/check-mem.sh

# check user
source inst-script/check-user.sh
check_user ALMiniumのインストール

# check old alminium existance
source inst-script/check-old-alm.sh

# OSを確認
source inst-script/check-os.sh

# check ruby
source inst-script/check-ruby.sh

# gitコマンドをチェック
source inst-script/check-git.sh

# 各種設定
source inst-script/config-alminium.sh

# 一時データ保存場所確保
mkdir -p ${ALM_SRC_DIR}/cache

# select db
source inst-script/select-db.sh

# pre install
source inst-script/pre-install.sh

# setup apache
source inst-script/config-apache.sh

# install Redmine
source inst-script/install-redmine.sh

# post install
echo "*** run post-install script ***"
source inst-script/post-install.sh

# プロジェクト作成時に自動的にリポジトリを作成するときに利用
#CHK=`egrep "reposman" /var/spool/cron/root`
#if [ "$CHK" = '' ]; then
#  echo "* * * * * /opt/alminium/extra/svn/reposman.rb -g apache -o apache -s /var/opt/alminium/git -u /var/opt/alminium/git -r localhost --scm git" >> /var/spool/cron/root
#fi

# 定期バックアップ設定
if [ "${ALM_ENABLE_AUTO_BACKUP}" = "y" ]; then
  source inst-script/config-backup.sh
fi

# setup for jenkins
if [ "${ALM_ENABLE_JENKINS}" = "y" ]; then
  source inst-script/install-jenkins.sh
fi

# config log directories
source inst-script/config-logs.sh

# 権限設定
# change the owner and group of the installation directory.
echo "*** set authorities ***"
sudo chown -R ${APACHE_USER}: ${ALM_INSTALL_DIR}/ || fatal_error_exit ${BASH_SOURCE}

 # restart service
source inst-script/service-restart.sh

# smelt completed
if [ "${ALM_UPGRADE}" != "y" ]; then
  echo ""
  echo "ALMiniumのインストールが終了しました。ブラウザーで、"
  echo "http://${ALM_HOSTNAME}${ALM_SUBDIR}"
  echo "をアクセスしてください。"
  echo "10秒程度の初期化が行われた後、最初の画面が表示されます。"
fi
