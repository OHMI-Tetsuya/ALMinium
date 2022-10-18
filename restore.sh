#!/bin/bash
#####################################################
# restore from ALMinium's backup.                   #
# 第1引数：バックアップファイル名またはファイスパス #
#  ファイル名の場合、デフォルトバックアップ         #
#  ディレクトリ(/var/opt/alminium-backup)が使われる #
# 第2引数：データベースホスト名                     #
# 第3引数：データベース管理者パスワード             #
#####################################################

# 各種ディレクトリ
ALM_SRC_DIR=${ALM_SRC_DIR:-$(cd $(dirname $0);pwd)}
ALM_VAR_DIR=${ALM_VAR_DIR:-/var/opt/alminium}
ALM_INSTALL_DIR=${ALM_INSTALL_DIR:-/opt/alminium}

# DBホスト、DBrootユーザーパスワード
ALM_DB_HOST=${2:-${ALM_DB_HOST}}
ALM_DB_HOST=${ALM_DB_HOST:-localhost}
ALM_DB_ROOT_PASS=${3:-${ALM_DB_ROOT_PASS}}

ALM_DEAULT_BACKUP_DIR=/var/opt/alminium-backup

# 実行ユーザーをチェック
if [ "`whoami`" != 'root' ]; then
    echo "ALMiniumのインストールはルートユーザで行う必要があります。"
    echo "rootユーザもしくはsudoで実行してください。"
    exit 1
fi

# バックアップファイルをチェック
if [ "$1" = "" ]; then
    echo "第1引数にバックアップファイルを指定してください。"
    echo "以下は、デフォルトバックアップディレクト配下の候補です。"
    ls ${ALM_DEAULT_BACKUP_DIR}/*-alm-backup.tar.gz
    exit 1
fi

# バックアップファイル名
ALM_BACKUP_FILE_NAME=`basename $1`

# バックアップディレクトリ
if [ "${ALM_BACKUP_FILE_NAME}" = "$1" ]; then
  ALM_BACKUP_DIR=${ALM_DEAULT_BACKUP_DIR}
else
  ALM_BACKUP_DIR=`dirname "$1"`
fi

# バックアップファイルパス
ALM_BACKUP_FILE_PATH=${ALM_BACKUP_DIR}/${ALM_BACKUP_FILE_NAME}

# バックアップファイルの存在を確認する
if [ ! -f "${ALM_BACKUP_FILE_PATH}" ]; then
  echo "指定したバックアップファイルが在りません。処理を中止します。"
  exit 1
fi

# リストア用一時ディレクトリ
ALM_RESTORE_TMP_DIR=${ALM_BACKUP_DIR}/tmp
if [ ! -d "${ALM_RESTORE_TMP_DIR}" ]; then
  mkdir "${ALM_RESTORE_TMP_DIR}"
fi

# リストア用一時ファイル
ALM_DB_BACKUP=${ALM_RESTORE_TMP_DIR}/db.dump
ALM_FILE_BACKUP=${ALM_RESTORE_TMP_DIR}/files.tar.gz
ALM_REPOS_BACKUP=${ALM_RESTORE_TMP_DIR}/repo.tar.gz

# move to sources directry
cd ${ALM_SRC_DIR}

# include functions
source inst-script/functions.sh

# バックアップの復元
echo "${ALM_BACKUP_FILE_PATH}を復元します。"
cd ${ALM_RESTORE_TMP_DIR}
if [ $? -ne 0 ]; then
  echo バックアップの一時復元ディレクトリ${ALM_RESTORE_TMP_DIR}に移動できませんでした。
  echo アクセス権やディスク容量などを確認してくだい。
  exit 1
fi
tar xzf ${ALM_BACKUP_FILE_PATH}
if [ $? -ne 0 ]; then
  echo バックアップの復元に失敗しました。
  echo ${ALM_RESTORE_TMP_DIR}のアクセス権やディスク容量などを確認してくだい。
  exit 1
fi

echo "***リポジトリーデータを復元しています..."
cd ${ALM_VAR_DIR} && tar xzf ${ALM_REPOS_BACKUP}
if [ $? -ne 0 ]; then
  echo "リポジトリーデータの復元に失敗しました。"
  exit 1
fi

echo "***Redmine添付ファイルを復元しています..."
cd ${ALM_INSTALL_DIR}/files/ && tar xzf ${ALM_FILE_BACKUP}
if [ $? -ne 0 ]; then
  echo "Redmine添付ファイルの復元に失敗しました。"
  exit 1
fi

# データベースの復元
if [ "${ALM_DB_BACKUP}" != "no" ]; then
  echo "***データベースを復元しています..."
  mysql `db_option_root` alminium < ${ALM_DB_BACKUP}
  if [ $? -ne 0 ]; then
    echo "データベースの復元に失敗しました。"
    exit 1
  fi
  echo "データベース復元が完了しました。"
  #データベースのマイグレーション
  echo "データベースのマイグレーションを実施します。"
  cd ${ALM_INSTALL_DIR}
  ${BUNDLER} exec rake db:migrate RAILS_ENV=production
  ${BUNDLER} exec rake redmine:plugins:migrate RAILS_ENV=production
  ${BUNDLER} exec rake tmp:cache:clear RAILS_ENV=production
  #${BUNDLER} exec rake tmp:sessions:clear RAILS_ENV=production
  if [ $? -ne 0 ]; then
    echo "データベースのマイグレーションに失敗しました。"
    exit 1
  fi
  echo "データベースのマイグレーションが完了しました。"
fi

cd ${ALM_SRC_DIR}
if [ -f inst-script/service-restart.sh ]; then
  echo "サービスを再起動します。"
  source ./inst-script/service-restart.sh
else
  echo "サービスを再起動してください。"
fi

