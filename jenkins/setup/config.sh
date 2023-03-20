#!/bin/bash

JENKINS_PLUGIN_DIR=/var/lib/jenkins/plugins

# create jenkins plugin directry
if [ ! -d ${JENKINS_PLUGIN_DIR} ]; then
  sudo mkdir -p ${JENKINS_PLUGIN_DIR}
  sudo chown jenkins:jenkins ${JENKINS_PLUGIN_DIR}
fi

# try connect to jenkins service up
curl --noproxy localhost http://localhost:8080/jenkins 2>/dev/null

echo セキュリティ解除
RET=-1
until  [ "$RET" -eq "0" ]
do
  echo "waiting for ready..."
  sleep 10
  wget --no-proxy --spider http://localhost:8080/jenkins/jnlpJars/jenkins-cli.jar 2>/dev/null
  RET=$?
done
sudo sed -i.org "s/<useSecurity>true/<useSecurity>false/" /var/lib/jenkins/config.xml
sudo systemctl restart jenkins.service || fatal_error_exit ${BASH_SOURCE}

# Jenkinsの設定を自動で進めるために初期ログインとアクセス権設定を手動で実施
#echo "## Jenkinsの設定を継続するため以下を実施してください"
#echo "## 1. ブラウザでhttp://${ALM_HOSTNAME}/jenkinsを表示"
#echo "## 2. 指示に従い初期設定を実施"
#echo "## 3. Jenkinsの管理において、「グローバルセキュリティの設定」をクリック"
#echo "## 4. アクセス制御→権限管理で「全員に許可」を選択"
#echo "## 5. 「保存」ボタンを押下"
#echo "## 以上を実施後、何らかのキーを押下してください。"
#read PROCEED

# download jenkins-cli.jar
RET=-1
until  [ "$RET" -eq "0" ]
do
  echo "Jenkinsへの接続を試みます..."
  sleep 10
  wget --no-proxy -O ${ALM_INSTALL_DIR}/bin/jenkins-cli.jar http://localhost:8080/jenkins/jnlpJars/jenkins-cli.jar 2>/dev/null
  RET=$?
done

# setting update center url
wget -O /tmp/default.js http://updates.jenkins-ci.org/update-center.json

## remove first and last line javascript wrapper
sed '1d;$d' /tmp/default.js > /tmp/default.json

## Now push it to the update URL
#curl --noproxy localhost -X POST -H "Accept: application/json" -d @/tmp/default.json http://localhost:8080/jenkins/updateCenter/byId/default/postBack --verbose
if [ ! -e /var/lib/jenkins/updates ]; then
  sudo mkdir -p /var/lib/jenkins/updates
fi
sudo cp -f /tmp/default.json /var/lib/jenkins/updates/

# Jenkinsのプロキシ設定
if [ x"$http_proxy" != x"" ]; then
  echo "** Jenkinsのプロキシ設定 **"
  # set proxy. sorry IPv4 only and user:pass not supported...
  proxyuser=`echo $http_proxy | sed -n 's/.*:\/\/\([a-zA-Z0-9]*\):.*/\1/p'`
  proxypass=`echo $http_proxy | sed -n 's/.*:\/\/[a-zA-Z0-9]*:\([a-zA-Z0-9:]*\)\@.*/\1/p'`
  echo
  echo proxyuser=$proxyuser
  echo proxypass=$proxypass

  if [ x"$proxyuser" != x"" ]; then
    http_proxy=`echo $http_proxy | sed "s/$proxyuser:$proxypass\@//"`
  fi

  proxyserver=`echo $http_proxy | cut -d':' -f2 | sed 's/\/\///g'`
  proxyport=`echo $http_proxy | cut -d':' -f3 | sed 's/\///g'`
  echo proxyserver=$proxyserver
  echo proxyport=$proxyport

  # get crumb
  jenkins_crumb=`curl --noproxy localhost 'http://localhost:8080/jenkins/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)'`
  echo "*** Jenkins Crumb = ${jenkins_crumb} ***"
  curl --noproxy localhost -X POST -H "${jenkins_crumb}" \
       --data "json={\"name\": \"$proxyserver\", \"port\": \"$proxyport\", \"userName\": \"$proxyuser\", \"password\": \"$proxypass\", \"noProxyHost\": \"\"}" \
       http://localhost:8080/jenkins/pluginManager/proxyConfigure --verbose
  RET=$?
  if [ "$RET" -ne "0" ]; then
    echo "proxy setting for jenkins fail"
    exit 1
  fi
  sudo systemctl restart jenkins.service || fatal_error_exit ${BASH_SOURCE}
fi

echo セキュリティ解除
#sed -i.org "s/<useSecurity>true/<useSecurity>false/" /var/lib/jenkins/config.xml
sudo sed -i.org \
    -e "s/<authorizationStrategy class=\"hudson.security.FullControlOnceLoggedInAuthorizationStrategy\">/<authorizationStrategy class=\"hudson.security.AuthorizationStrategy\$Unsecured\"\/>\n  <\!-- <authorizationStrategy class=\"hudson.security.FullControlOnceLoggedInAuthorizationStrategy\"> -->/" \
    -e "s/<denyAnonymousReadAccess/<\!-- <denyAnonymousReadAccess/" \
    -e "s/\/denyAnonymousReadAccess>/\/denyAnonymousReadAccess> -->/" \
    -e "s/<\/authorizationStrategy>/<\!-- <\/authorizationStrategy> -->/" \
    /var/lib/jenkins/config.xml 
sudo service jenkins restart

# プラグインインストール
sleep 10
mkdir -p tmp
pushd tmp

install_jenkins_plugins() {
  local plugin_name=${1}
  if [ "${proxyserver}" != "" ]; then
    proxy_opt=`echo -Dhttp.proxyHost=${proxyserver} -Dhttps.proxyHost=${proxyserver} -Dhttp.nonProxyHosts="localhost|127.0.0.1"`
    if [ "${proxyport}" != "" ]; then
      proxy_opt=`echo ${proxy_opt} -Dhttp.proxyPort=${proxyport} -Dhttps.proxyPort=${proxyport}`
    fi
  fi
  if [ ! -d ${JENKINS_PLUGIN_DIR}/${plugin_name} ]; then
    local result=-1
    until  [ "${result}" -eq "0" ]; do
      sleep 3
      java ${proxy_opt} -jar ${ALM_INSTALL_DIR}/bin/jenkins-cli.jar \
	   -s http://localhost:8080/jenkins/ install-plugin ${plugin_name}
      result=$?
      if [ "${result}" != "0" ]; then
        echo "### Jenkinsプラグインのインストール中にエラーが発生しました。"
        echo "### 再度、プラグインのインストールを試みます。"
      fi
    done
  fi
}

install_jenkins_plugins reverse-proxy-auth-plugin
#install_jenkins_plugins persona
install_jenkins_plugins git
install_jenkins_plugins redmine
install_jenkins_plugins dashboard-view

popd
rm -rf tmp

# persona-hudmi取得
if [ ! -d /var/lib/jenkins/persona ]; then
  sudo bash -cl "git clone https://github.com/okamototk/jenkins-persona-hudmi /var/lib/jenkins/persona" || fatal_error_exit ${BASH_SOURCE}
fi

# 設定ファイルを配置
if [ ! -f /var/lib/jenkins/config.xml ]; then
  sudo cp jenkins/config.xml /var/lib/jenkins/config.xml
fi
sudo chown -R jenkins:jenkins /var/lib/jenkins/

# Jenkins再起動
sudo systemctl restart jenkins.service || fatal_error_exit ${BASH_SOURCE}

# 初期化時間を見越して少し待つ
echo "Jenkins初期化中..."
sleep 30

# Redmineログイン連携設定（手動）
echo "## Jenkinsの設定が終わりました。"
echo "## 初期化処理を以下の手順で実施してください。"
echo "## 3～7はRedmineユーザーでJenkinsへログインできるようにする場合に実施してください。"
echo "## ※ブラウザで表示エラーになる場合は、しばらく待ってから以下を実施してください。"
echo "## 1. ブラウザでhttp://${ALM_HOSTNAME}/jenkinsを表示"
echo "## 2. 初期設定後表示されたJenkinsの画面にて、「Jenkinsの管理」→「グローバルセキュリティの設定」を選択"
echo "## 3. ユーザー情報で「Redmineユーザー認証」を選択"
echo "## 4. 「データベース名」、「DBユーザー」、「DBパスワード」にalminiumと記載（その他はデフォルト値のまま）"
echo "## 5. Redmineバージョンで「1.2.0以上」を選択"
echo "## 6. 「保存」ボタンを押下"
echo "※上記設定等、正常に行われたことを確認した後、適切な権限設定を行った上で、運用してください。"
echo "## インストール処理を継続するために、何らかのキーを押下してください。"
read PROCEED
