#!/bin/sh

sudo yum install -y fontconfig java-11-openjdk
while [ "`java -version 2>&1 | grep 11.`" = "" ]
do
  echo "######################################################"
  echo "### デフォルトのJAVAがバージョン11以外になっています。"
  echo "### デフォルトのJAVAバージョンを11にして下さい。"
  echo "######################################################"
  sudo alternatives --config java
done

#wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
#rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum install -y jenkins

#sed -i 's/JENKINS_JAVA_OPTIONS="-Djava.awt.headless/JENKINS_JAVA_OPTIONS="-Dhudson.diyChunking=false -Djava.awt.headless/' /etc/sysconfig/jenkins

#sed -i 's/JENKINS_ARGS=""/JENKINS_ARGS="--prefix=\/jenkins"/' /etc/sysconfig/jenkins
sudo mkdir -p /etc/systemd/system/jenkins.service.d
sudo bash -c "echo -e \"[Service]\nEnvironment=\"JENKINS_PREFIX=/jenkins\"\n\" > /etc/systemd/system/jenkins.service.d/override.conf"
sudo service jenkins restart
sudo systemctl enable jenkins

