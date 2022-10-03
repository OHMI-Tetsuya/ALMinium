#!/bin/sh

yum install -y fontconfig java-11-openjdk
while [ "`java -version 2>&1 | grep 11.`" = "" ]
do
  echo "######################################################"
  echo "### デフォルトのJAVAがバージョン11以外になっています。"
  echo "### デフォルトのJAVAバージョンを11にして下さい。"
  echo "######################################################"
  alternatives --config java
done

#wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
#rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum install -y jenkins

#sed -i 's/JENKINS_JAVA_OPTIONS="-Djava.awt.headless/JENKINS_JAVA_OPTIONS="-Dhudson.diyChunking=false -Djava.awt.headless/' /etc/sysconfig/jenkins

#sed -i 's/JENKINS_ARGS=""/JENKINS_ARGS="--prefix=\/jenkins"/' /etc/sysconfig/jenkins
mkdir -p /etc/systemd/system/jenkins.service.d
echo -e "[Service]\nEnvironment=\"JENKINS_PREFIX=/jenkins\"\n" > /etc/systemd/system/jenkins.service.d/override.conf
service jenkins restart
