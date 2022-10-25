#!/bin/bash
############################################################
# upgrader for ALMinium.
# 第1引数：バックアップディレクトリ
#  defaultは/var/opt/alminium-backup
#  "-"を指定したときはdefaultディレクトリを利用
# 第2引数：データベースホスト名
# 第3引数：データベース管理者パスワード
############################################################
ALM_SRC_DIR=$(cd $(dirname $0);pwd)
ALM_ETC_DIR=${ALM_ETC_DIR:-/etc/opt/alminium}
ALM_VAR_DIR=/var/opt/alminium
ALM_INSTALL_DIR=${ALM_INSTALL_DIR:-/opt/alminium}

ALM_BACKUP_DIR=${1:--}
ALM_DB_HOST=${2:-${ALM_DB_HOST}}
ALM_DB_HOST=${ALM_DB_HOST:-localhost}
ALM_DB_ROOT_PASS=${3:-${ALM_DB_ROOT_PASS}}

# move to sources directry
cd ${ALM_SRC_DIR}

# 実行ユーザーをチェック
source inst-script/check-user.sh

# ALMiniumインストール状況をチェック
if [ ! -e ${ALM_INSTALL_DIR}/app ]; then
  echo "ALMiniumインストールディレクトリが見つかりませんでした。処理を中止します"
  exit 1
fi

# OSをチェック
source inst-script/check-os.sh

# バックアップの確認 
echo "#####################################################################"
echo "# 途中にエラーが発生した場合、復活できなくなる可能性があるため、    #"
echo "# スナップショットをとるなど、後戻りできるようにしておいてください。#"
echo "# また、ご自身によるカスタマイズ（プラグイン、設定ファイル等）があ  #"
echo "# る場合は、アップグレードすることにより削除・上書きされてしまいま  #"
echo "# すので、アップグレード後に手動でカスタマイズを実行する必要があり  #"
echo "# ます。処理を続行する場合はEnterキーを押下してください。           #"
echo "#####################################################################"
read DO_CONTINUE

# バックアップ実行
source backup.sh ${ALM_BACKUP_DIR} ${ALM_DB_HOST} ${ALM_DB_ROOT_PASS}
if [ $? -gt 0 ]; then
  echo "バックアップに失敗したため、処理を中止します"
  exit 1
fi

# ログをバックアップ
backup_log() {
  local log_dir=$1
  local backup_dir=$2
  if [ -d ${log_dir} ]; then
    cp -pr ${log_dir}/ ${backup_dir}
  fi
}

mkdir -p /tmp/alminium-logs
backup_log ${ALM_INSTALL_DIR}/log /tmp/alminium-logs
backup_log /var/log/${MYSQL_LOG_DIR} /tmp/alminium-logs
backup_log /var/log/${APACHE_LOG_DIR} /tmp/alminium-logs
backup_log /var/log/jenkins /tmp/alminium-logs

# 設定ファイルのバックアップ
backup_conf() {
  local conf_dir=$1
  local conf_name=$2
  local backup_dir=$3
  mkdir ${backup_dir}/${conf_name}
  cp -pr ${conf_dir}/* ${backup_dir}/${conf_name}
  echo "these were stored in ${conf_dir}." > ${backup_dir}/${conf_name}/README.txt
}

ALM_CONFIGS_BACKUP_DIR=${ALM_BACKUP_DIR}/configs-${ALM_BACKUP_ID}
mkdir ${ALM_CONFIGS_BACKUP_DIR}
backup_conf ${ALM_ETC_DIR} apache_conf ${ALM_CONFIGS_BACKUP_DIR}
backup_conf ${ALM_INSTALL_DIR}/config alminium_config ${ALM_CONFIGS_BACKUP_DIR}
backup_conf ${ALM_INSTALL_DIR}/hooks alminium_hooks ${ALM_CONFIGS_BACKUP_DIR}
echo
echo "ApacheおよびRedmine関連の設定ファイルを${ALM_CONFIGS_BACKUP_DIR}にバックアップしました。ご自身で加えた変更を反映する場合にご利用ください。"

#バックアップ結果の確認
echo ""
echo "ディレクトリ${ALM_BACKUP_DIR}にバックアップファイル($ALM_BACKUP_NAME)が作成されていることを確認してください。問題がなければEnterキーを押下してください。中止する場合はCtrl+C。"
echo "#### 何らかのエラーがコンソールに出力されている場合はバックアップに失敗している可能性がありますので、中止(Ctrl+C)してください。"
echo "#### エラー発生等により中止した場合は、upgradeファイルを参考に手動によりアップグレードを実行することをお勧めします。"
read DO_CONTINUE

#
# alminium再インストール
# 
echo ""
echo ""
echo "ALMiniumのアップグレードを開始・・・"

# アップグレード対象を削除
if [ -f ${ALM_INSTALL_DIR}/subdirname ]; then
  rm -f /var/www/html`cat ${ALM_INSTALL_DIR}/subdirname`
fi
rm -fr ${ALM_INSTALL_DIR}/* ${ALM_INSTALL_DIR}/.[^.]*
rm -fr cache/* *.installed
rm -fr ${ALM_ETC_DIR}/passenger.*

# Jenkinsが設置されているか否か
##############################################################################
# \"JENKINS\"だと"JENKINS"(ダブルクォートJENKINSダブルクォート)でgrepするので
# 常に""でJENKINS_INSTALLED=yが実行されていた
##############################################################################
#if [ "$(grep \"JENKINS\" /etc/opt/alminium/alminium.conf)" = "" ]; then
if [ "$(grep "JENKINS" /etc/opt/alminium/alminium.conf)" = "" ]; then
  JENKINS_INSTALLED=y
fi

#　install ALMinium by smelt
ALM_UPGRADE=y
source ./smelt.sh ${ALM_DB_HOST} ${ALM_DB_ROOT_PASS}

#バックアップの復元
ALM_DB_RESTORE=no
source ./restore.sh ${ALM_BACKUP_DIR}/${ALM_BACKUP_NAME} ${ALM_DB_HOST} ${ALM_DB_ROOT_PASS}

# log復元
restore_log() {
  local LOG_DIR="/tmp/alminium-logs/$1"
  local TO_PATH=$2
  if [ "${TO_PATH}" = "" ];then TO_PATH=$1; fi
  if [ -d ${LOG_DIR} -a "`ls ${LOG_DIR} 2>/dev/null`" != "" ]; then
    cp -pr ${LOG_DIR}/* ${ALM_LOG_DIR}/${TO_PATH}/
  fi
}

restore_log log redmine
restore_log ${MYSQL_LOG_DIR}
restore_log ${APACHE_LOG_DIR}
restore_log jenkins

echo ""
echo "以上でアップグレードは終了です。途中にエラーが発生した場合は、元の状態に戻して手動でアップグレードを実施してください。"

