#!/bin/bash
# ALMinium関連のログをまとめて管理する

# backup log and new log's directory setting function
backup_and_new_logdir() {
  local parent_dir=$1
  local old_log_dir=$2
  local new_log_dir=$3
  local owner=$4
  local group=$5

  pushd ${parent_dir}
  # ログディレクトリが規定の場所に実態として存在する場合に
  # log/alminium配下に移動する
  if [ -d ${old_log_dir} -a ! -L ${old_log_dir} ]; then
    if [ "`sudo ls ${old_log_dir}`" != "" ]; then
      sudo mkdir -p ${old_log_dir}.backup
      sudo tar cvfz ${old_log_dir}.backup/"`date +%F-%H-%M-%S`".tar.gz ${old_log_dir}
#	  echo "sudo cp -p ${old_log_dir}/* ${ALM_LOG_DIR}/${new_log_dir}/"
#	  pwd
#      sudo ls -al ${old_log_dir} 
#      sudo cp -p ${old_log_dir}/* ${ALM_LOG_DIR}/${new_log_dir}/
      sudo bash -c "cp -p ${old_log_dir}/* ${ALM_LOG_DIR}/${new_log_dir}/"
    fi
    sudo rm -r ${old_log_dir}
    sudo ln -s ${ALM_LOG_DIR}/${new_log_dir} ${parent_dir}/${old_log_dir}
  fi
  sudo chown -R ${owner}:${group} ${ALM_LOG_DIR}/${new_log_dir}
  popd
}

# each log's configuration
sudo mkdir -p ${ALM_LOG_DIR}
sudo mkdir -p ${ALM_LOG_DIR}/redmine
sudo mkdir -p ${ALM_LOG_DIR}/${APACHE_LOG_DIR}
backup_and_new_logdir "${ALM_INSTALL_DIR}" "log" "redmine" "${APACHE_USER}" "${APACHE_USER}"
backup_and_new_logdir "/var/log" "${APACHE_LOG_DIR}" "${APACHE_LOG_DIR}" "root" "root"

# jenkins log configuration
if [ "${ALM_ENABLE_JENKINS}" = "y" ]; then
  sudo mkdir -p ${ALM_LOG_DIR}/jenkins
  backup_and_new_logdir "/var/log" "jenkins" "jenkins" "jenkins" "jenkins"
fi

# db log configuration
if [ "${ALM_DB_SETUP}" = "y" -a "${ALM_USE_EXISTING_DB}" != "y" ]; then
  sudo mkdir -p ${ALM_LOG_DIR}/${MYSQL_LOG_DIR}
  backup_and_new_logdir "/var/log" "${MYSQL_LOG_DIR}" "${MYSQL_LOG_DIR}" "mysql" "adm"
  # ubuntu1604 apparmor setting
  if [ "${APPARMOR_ENABLED}" != "" ]; then
    sudo sed -i "s|/var/log/mysql/|/var/log/alminium/mysql/|" /etc/apparmor.d/usr.sbin.mysqld
  fi
fi
