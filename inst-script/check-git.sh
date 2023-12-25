#!/bin/bash
#
# gitコマンドをチェック
#
if [ "`which git`" = "" ]; then
  echo
  echo gitコマンドがインストールされていません。
  echo gitコマンドをインストールしてから再度実行してください。
  echo 処理を終了します。
  exit 1
else
#  GIT_VER=`git --version | cut -c 13-15`
  GIT_VER=$(git --version | cut -c 13- | (IFS=. read -r major minor build revision; printf "%2d%02d%02d%02d" ${major:-0} ${minor:-0} ${build:-0} ${revision:-0}))
  # 古いgitのときはアップグレード
#  if [ `echo "${GIT_VER} >= 1.9" | bc` = 0 ]; then
  if [ ${GIT_VER} -lt ${ALM_GIT_MIN_VERSION_NUM} ]; then
    if [ ${ALM_GIT_AUTO_UPGRADE} = 'y' ]; then
      GIT_UPDATE=y
    else
      echo
      echo
      echo gitのバージョンが古いためALMiniumが正しく動作しない可能性があります。
      echo 本ソフトウェアでは version${ALM_GIT_MIN_VERSION}以上を推奨しています。
      echo gitのバージョンを${ALM_LOCAL_INSTALL_GIT_VERSION}にアップグレードしても良い場合は'y'を
      echo さもなくば'N'を選択してください。
      echo 'N'を選択した場合は、ALMiniumインストールした後、
      echo ご自身でgitのバージョンアップを実施してください。
      echo -n "gitをアップグレードしても良いですか？(y/N):"
      read GIT_UPDATE
    fi
  fi
fi
