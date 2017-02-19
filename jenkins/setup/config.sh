#!/bin/bash

JENKINS_PLUGIN_DIR=/var/lib/jenkins/plugins

if [ ! -d ${JENKINS_PLUGIN_DIR} ]
then
  mkdir ${JENKINS_PLUGIN_DIR}
  chown jenkins:jenkins ${JENKINS_PLUGIN_DIR}
fi

# download jenkins-cli.jar
echo "## Jenkinsの設定を継続するため以下を実施してください"
echo "## 1. ブラウザでhttp://${ALM_HOSTNAME}:8080/jenkinsを表示"
echo "## 2. 指示に従い初期設定を実施"
echo "## 3. Jenkinsの管理において、「グローバルセキュリティの設定」をクリック"
echo "## 4. アクセス制御→権限管理で「全員に許可」を選択"
echo "## 5. 「保存ボタン」を押下"
echo "## 以上を実施後、何らかのキーを押下してください。"
read PROCEED

RET=-1
until  [ "$RET" -eq "0" ]
do
  sleep 3
  wget --no-proxy -O $INSTALL_DIR/bin/jenkins-cli.jar http://localhost:8080/jenkins/jnlpJars/jenkins-cli.jar
  RET=$?
done

wget -O /tmp/default.js http://updates.jenkins-ci.org/update-center.json

# remove first and last line javascript wrapper
sed '1d;$d' /tmp/default.js > /tmp/default.json

# Now push it to the update URL
#curl --noproxy localhost -X POST -H "Accept: application/json" -d @/tmp/default.json http://localhost:8080/jenkins/updateCenter/byId/default/postBack --verbose
if [ ! -e /var/lib/jenkins/updates ]
then
  mkdir /var/lib/jenkins/updates
fi
cp -f /tmp/default.json /var/lib/jenkins/updates/

# Jenkinsのプロキシ設定
if [ x"$http_proxy" != x"" ]
then
  # set proxy. sorry IPv4 only and user:pass not supported...
  proxyuser=`echo $http_proxy | sed -n 's/.*:\/\/\([a-zA-Z0-9]*\):.*/\1/p'`
  proxypass=`echo $http_proxy | sed -n 's/.*:\/\/[a-zA-Z0-9]*:\([a-zA-Z0-9:]*\)\@.*/\1/p'`
  echo
  echo proxyuser=$proxyuser
  echo proxypass=$proxypass

  if [ x"$proxyuser" != x"" ]
  then
    http_proxy=`echo $http_proxy | sed "s/$proxyuser:$proxypass\@//"`
  fi

  proxyserver=`echo $http_proxy | cut -d':' -f2 | sed 's/\/\///g'`
  proxyport=`echo $http_proxy | cut -d':' -f3 | sed 's/\///g'`
  echo proxyserver=$proxyserver
  echo proxyport=$proxyport

  curl --noproxy localhost -X POST --data "json={\"name\": \"$proxyserver\", \"port\": \"$proxyport\", \"userName\": \"$proxyuser\", \"password\": \"$proxypass\", \"noProxyHost\": \"\"}" http://localhost:8080/jenkins/pluginManager/proxyConfigure --verbose
  RET=$?
  if [ "$RET" -ne "0" ]
  then
    echo "proxy setting for jenkins fail"
    exit 1
  fi
  #service jenkins restart
fi

# プラグインインストール
mkdir tmp
pushd tmp

install_jenkins_plugins() {
  local plugin_name=${1}
  if [ ! -d ${JENKINS_PLUGIN_DIR}/${plugin_name} ]; then
    local resalt=-1
    until  [ "${resalt}" -eq "0" ]; do
      sleep 3
      java -jar $INSTALL_DIR/bin/jenkins-cli.jar \
	   -s http://localhost:8080/jenkins/ install-plugin ${plugin_name}
      resalt=$?
      if [ "${resalt}" != "0" ]; then
        echo "### プラグインインストール中にエラーが発生しました。"
        echo "### 再度、プラグインのインストールを試みます。"
      fi
    done
  fi
}

install_jenkins_plugins reverse-proxy-auth-plugin
install_jenkins_plugins persona
install_jenkins_plugins git
install_jenkins_plugins redmine
install_jenkins_plugins dashboard-view

popd
rm -rf tmp

sleep 10

# persona-hudmi取得
if [ ! -d /var/lib/jenkins/persona ]
then
  git clone https://github.com/okamototk/jenkins-persona-hudmi /var/lib/jenkins/persona
fi

if [ ! -f /var/lib/jenkins/config.xml ]
then
  cp jenkins/config.xml /var/lib/jenkins/config.xml
fi

chown -R jenkins:jenkins /var/lib/jenkins/
service jenkins restart

echo "## Jenkinsの設定が終わりました。"
echo "## RedmineユーザーでJeninsへログインできるようにする場合は、以下を実施してください"
echo "## 1. Jenkinsの管理→グローバルセキュリティーの設定→アクセス制御で「Redmineユーザー認証」を選択"
echo "## 2. データベース名、DBユーザー、DBパスワードにalminiumと記載"
echo "## 3. Redmineバージョンで「1.2.0以上」を選択"
echo "## インストール処理を継続するには、何らかのキーを押下してください。"
read PROCEED
