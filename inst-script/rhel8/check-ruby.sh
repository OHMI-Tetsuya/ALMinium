#!/bin/bash

# check ruby
if [ "`sudo bash -cl \"which ruby\"`" == "" ]; then
  echo -e -n "\nパッケージ版のVersion ${ALM_RHEL8_PKG_INSTALL_RUBY_VERSION}系のrubyをインストールします。"
  echo -e -n "\nインストールを中止する場合は、ctrl+cでスクリプトの実行を中断してください。"
  echo -e -n "\nrubyをインストールしても良いですか？(y/N):"
  read RUBY_PKG_INSTALL
  DNF_MODULE_SETTING_RUBY="y"
else
  RUBY_VER=$(sudo bash -cl "ruby --version" 2>&1 | cut -c 6-10)
  RUBY_VER_NUM=$(echo "${RUBY_VER}" | (IFS=. read -r major minor build; printf "%2d%02d%02d" ${major:-0} ${minor:-0} ${build:-0}))
  if [ ! \( ${RUBY_VER_NUM} -ge ${ALM_RUBY_GE_VER_NUM} -a ${RUBY_VER_NUM} -lt ${ALM_RUBY_LT_VER_NUM} \) ]; then
    if [ "`sudo bash -cl \"which rbenv\"`" != "" ]; then
      echo -e -n "\nrbenv版のVersion ${RUBY_VER}のrubyがインストールされています。"
      echo -e -n "\n新たにrbenv版のVersion ${ALM_LOCAL_INSTALL_RUBY_VERSION}のrubyをインストールします。"
      echo -e -n "\nインストールを中止する場合は、ctrl+cでスクリプトの実行を中断してください。"
      echo -e -n "\nrubyをインストールしても良いですか？(y/N):"
      read RUBY_LOCAL_INSTALL
#  sudo apt-get -y autoremove || fatal_error_exit ${BASH_SOURCE}
    elif [ "`rpm -qa | grep ruby`" != "" ]; then
      echo -e -n "\nパッケージ版のVersion ${RUBY_VER}のrubyがインストールされています。"
      echo -e -n "\n新たにパッケージ版のVersion ${ALM_RHEL8_PKG_INSTALL_RUBY_VERSION}系のrubyをインストールし使用します。"
      echo -e -n "\nインストールを中止する場合は、ctrl+cでスクリプトの実行を中断してください。"
      echo -e -n "\nrubyをインストールしても良いですか？(y/N):"
      read RUBY_PKG_INSTALL
      DNF_MODULE_SETTING_RUBY="y"
    else
      echo -e -n "\nrbenv版以外のVersion ${RUBY_VER}のrubyがインストールされています。"
      echo -e -n "\n新たにrbenv版のVersion ${ALM_LOCAL_INSTALL_RUBY_VERSION}のrubyをインストールします。"
      echo -e -n "\nインストールを中止する場合は、ctrl+cでスクリプトの実行を中断してください。"
      echo -e -n "\nrubyをインストールしても良いですか？(y/N):"
      read RUBY_LOCAL_INSTALL
    fi
  elif [ "`rpm -qa | grep ruby`" != "" ]; then
    if [ "`rpm -qa | grep ruby-devel`" == "" ]; then
      RUBY_PKG_INSTALL="y"
      DNF_MODULE_SETTING_RUBY="N"
    fi
  fi
fi
