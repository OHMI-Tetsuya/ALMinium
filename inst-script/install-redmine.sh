#!/bin/bash
###################
# install Redmine #
###################


## functions ##

# download redmine
download_redmine() {
  mkdir -p ${ALM_INSTALL_DIR}
  cd cache
  wget ${RM_ARC}
  tar zxf ${RM_VER}.tar.gz
  cd ..
  cp -fr cache/redmine-${RM_VER}/* ${ALM_INSTALL_DIR}/
  rm -fr cache/redmine-${RM_VER}
  # redmine_backlogsプラグイン利用時にプロジェクトチケットリスト
  # 表示エラーになる問題に対処
  patch_for_issues_26637
}

# patch to  http://www.redmine.org/issues/26637
# redmineのバグか否か不明だが、以下の対処法を発見したので適用する
# ちなみに、本問題は、redmine_backlogsプラグイン利用時に問題が発生する
patch_for_issues_26637() {
  echo patch to fix http://www.redmine.org/issues/26637
  pushd ${ALM_INSTALL_DIR}
  sed -i.org 's/filter.remote/filter[:remote]/' app/models/query.rb
  popd
}

# setup configurations
setup_configurations() {
  # put config files
  cp -f  redmine/Gemfile.local   ${ALM_INSTALL_DIR}/
  cp -fr redmine/config/*        ${ALM_INSTALL_DIR}/config/
  cp -fr redmine/public/themes/* ${ALM_INSTALL_DIR}/public/themes/
  cp     ./{backup.sh,restore.sh} ${ALM_INSTALL_DIR}/
  mkdir ${ALM_INSTALL_DIR}/inst-script
  cp ./inst-script/{check-user.sh,config-backup.sh,functions.sh} \
     ./inst-script/${OS}/service-restart.sh \
     ${ALM_INSTALL_DIR}/inst-script/
  ln -s ${ALM_INSTALL_DIR}/inst-script/* ${ALM_INSTALL_DIR}/

  # update db-config
  sed -i.org "s/localhost/${ALM_DB_HOST}/" \
             ${ALM_INSTALL_DIR}/config/database.yml
}

# setup hooks
setup_hooks() {
  mkdir -p ${ALM_INSTALL_DIR}/bin
  cp -fr redmine/bin/* ${ALM_INSTALL_DIR}/bin/
  if [ "${ALM_SUBDIR}" != "" ]; then
    sed -i "s|localhost|localhost${ALM_SUBDIR}|g" \
           ${ALM_INSTALL_DIR}/bin/alm-sync-scm
    chmod +x ${ALM_INSTALL_DIR}/bin/alm-sync-scm
  fi
  cp -fr   redmine/hooks ${ALM_INSTALL_DIR}/
}

#create repository's directories
create_repo_dir() {
  if [ "${ALM_UPGRADE}" != "y" ]; then
    # create directory for vcs
    mkdir -p ${ALM_VAR_DIR}/{git,svn,hg,maven,github}
    chown -R ${APACHE_USER}:${APACHE_USER} ${ALM_VAR_DIR}/*
  fi
}

# gem packages installation
install_gems() {
  pushd ${ALM_INSTALL_DIR}
  # if no need passenger gem, comment out it on redmine's Gemfile.local
  if [ "${ALM_PASSSENGER_PACKAGE_AVAILABLE}" = "1" ]; then
    sed -i.org "s/gem 'passenger'/#gem 'passenger'/" Gemfile.local
  fi

  # redmineに必要なgemをインストール
  ${BUNDLER} install --path vendor/bundle \
               --without development test postgresql sqlite xapian
  popd
}

# create secret token
create_redmine_token() {
  pushd ${ALM_INSTALL_DIR}
  ${BUNDLER} exec rake generate_secret_token
  popd
}

# create DB
create_db() {
  if [ "${ALM_DB_SETUP}" = "y" ]; then
    source redmine/setup/create-db.sh
  fi
}

# setup DB
setup_db() {
  if [ "${ALM_DB_SETUP}" = "y" ]; then
    source redmine/setup/setup-db.sh
  fi
}

## sctips ##
echo "*** install Redmine ***"

echo "** create redmine database **"
create_db

echo "** download Redmine **"
# download and put alminium's home dir
download_redmine

echo "** setup configurations **"
setup_configurations

echo "** create repositries' directories **"
create_repo_dir

echo "** install hooks **"
setup_hooks

# install plugins
echo "** install redmine plugins **"
source redmine/setup/install-plugins.sh

echo "** install gems **"
install_gems

echo "** create redmine token **"
# セッションストア秘密鍵を生成
create_redmine_token

echo "** setup redmine db **"
setup_db

if [ "${ALM_ENABLE_JENKINS}" = "y" -o "${JENKINS_INSTALLED}" = "y" ]; then
  echo "instll redmine pluguins for jenkins **"
  # jenkins関連プラグイン
  # この位置でインストールしないとエラーになる
  source redmine/setup/install-plugins-jenkins.sh
fi

echo "** set authorities **"
# 権限設定
chown -R ${APACHE_USER}:${APACHE_USER} ${ALM_INSTALL_DIR}/*
