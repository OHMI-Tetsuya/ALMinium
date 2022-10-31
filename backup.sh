#!/bin/bash
############################################################
# backup for ALMinium.
# 第1引数：バックアップディレクトリ
#  defaultは/var/opt/alminium-backup
#  "-"を指定したときはdeaultディレクトリを利用
# 第2引数：データベースホスト名
# 第3引数：データベース管理者パスワード
############################################################

# 各種ディレクトリ
ALM_SRC_DIR=${ALM_SRC_DIR:-$(cd $(dirname $0);pwd)}
ALM_VAR_DIR=${ALM_VAR_DIR:-/var/opt/alminium}
ALM_INSTALL_DIR=${ALM_INSTALL_DIR:-/opt/alminium}

# DBホスト、DBrootユーザーパスワード
ALM_DB_HOST=${2:-${ALM_DB_HOST}}
ALM_DB_HOST=${ALM_DB_HOST:-localhost}
ALM_DB_ROOT_PASS=${3:-${ALM_DB_ROOT_PASS}}

ALM_CURRENT_DIR=`pwd`

# move to sources directry
cd ${ALM_SRC_DIR}

# include functions
source inst-script/functions.sh

# backup directry
if [ "$1" != "" -a "$1" != "-" ]; then
  if [ "`echo $1 | cut -c 1`" = "/" ]; then
    ALM_BACKUP_DIR=$1
  else
    ALM_BACKUP_DIR=${ALM_CURRENT_DIR}/$1
  fi
else
  # デフォルトバックアップディレクトリを設定
  ALM_BACKUP_DIR=/var/opt/alminium-backup
fi

#cronでも動くようにユーザチェックを外す
# 実行ユーザーチェック
#source inst-script/check-user.sh
#check_user ALMiniumのバックアップ

#バックアップディレクトリのチェック
if [ ! -d ${ALM_BACKUP_DIR} ]; then
  mkdir -p ${ALM_BACKUP_DIR}
fi

# バックアップファイル名決定
ALM_BACKUP_ID=`date +"%Y-%m-%d-%H-%M-%S"`
ALM_DBBACKUP_NAME=db.dump
ALM_FILE_BACKUP=files.tar.gz
ALM_REPOS_BACKUP=repo.tar.gz
ALM_BACKUP_NAME=${ALM_BACKUP_ID}-alm-backup.tar.gz

# バックアップ開始
echo "[`date`] ALMiniumのデータのバックアップを開始します。"
echo "バックアップファイル名 : ${ALM_BACKUP_DIR}/${ALM_BACKUP_NAME}"

# バックアップ結果チェック
check_backup_result() {
  if [ "$3" = "0" -a -f ${ALM_BACKUP_DIR}/$1 -a -s ${ALM_BACKUP_DIR}/$1 ]; then
    echo "$2(${ALM_BACKUP_DIR}/$1)が成功しました。"
  else
    echo "$2(${ALM_BACKUP_DIR}/$1)が失敗しました。"
    unset RESULT
    exit 1
  fi
}

echo "MySQLデータベースをバックアップします。"
export RESULT=0
sudo bash -c "mysqldump `db_option_root` alminium > ${ALM_BACKUP_DIR}/${ALM_DBBACKUP_NAME} || RESULT=$?"
check_backup_result ${ALM_DBBACKUP_NAME} "データベースバックアップ" ${RESULT}

#redmineの添付ファイルをバックアップ
echo "Redmineの添付ファイルをバックアップします。"
pushd ${ALM_INSTALL_DIR}/files/
export RESULT=0
sudo tar czf ${ALM_BACKUP_DIR}/${ALM_FILE_BACKUP} . || RESULT=$?
check_backup_result ${ALM_FILE_BACKUP} "添付ファイルバックアップ" ${RESULT}
popd

#ソースコードリポジトリ
echo "ソースコードリポジトリをバックアップします。"
export RESULT=0
pushd ${ALM_VAR_DIR}/
sudo tar czf ${ALM_BACKUP_DIR}/${ALM_REPOS_BACKUP} . || RESULT=$?
check_backup_result ${ALM_REPOS_BACKUP} "ソースコードリポジトリバックアップ" ${RESULT}
popd

# バックアップ統合
pushd ${ALM_BACKUP_DIR}
export RESULT=0
sudo tar czf ./${ALM_BACKUP_NAME} \
    ./${ALM_DBBACKUP_NAME} ./${ALM_FILE_BACKUP} ./${ALM_REPOS_BACKUP} || result=$?
check_backup_result ${ALM_BACKUP_NAME} "バックアップファイル統合" ${RESULT}

# バックアップ終了
echo "[`date`]  ALMiniumのデータのバックアップが終了しました。"
echo "バックアップファイル名：${ALM_BACKUP_DIR}/${ALM_BACKUP_NAME}"
unset RESULT

# 古いバックアップファイルを削除
if [ "${ALM_BACKUP_EXPIRY}" != "" ]; then
  echo -n "[`date`]  ${ALM_BACKUP_EXPIRY}日経過した"
  echo    "バックアップファイルを削除します。"
  sudo find ${ALM_BACKUP_DIR}/*.tar.gz \
       -mtime +${ALM_BACKUP_EXPIRY} -exec rm -f {} \;
fi
popd

