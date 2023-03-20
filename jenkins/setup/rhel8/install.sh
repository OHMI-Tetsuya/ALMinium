#!/bin/bash

sudo dnf install -y fontconfig java-17-openjdk || fatal_error_exit ${BASH_SOURCE}
while [ "`java -version 2>&1 | grep 17.`" = "" ]
do
  echo "######################################################"
  echo "### デフォルトのJAVAがバージョン17以外になっています。"
  echo "### デフォルトのJAVAバージョンを17にして下さい。"
  echo "######################################################"
  sudo alternatives --config java || fatal_error_exit ${BASH_SOURCE}
done

#wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo || fatal_error_exit ${BASH_SOURCE}
#rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key || fatal_error_exit ${BASH_SOURCE}
sudo dnf install -y jenkins || fatal_error_exit ${BASH_SOURCE}

#sed -i 's/JENKINS_JAVA_OPTIONS="-Djava.awt.headless/JENKINS_JAVA_OPTIONS="-Dhudson.diyChunking=false -Djava.awt.headless/' /etc/sysconfig/jenkins

#sed -i 's/JENKINS_ARGS=""/JENKINS_ARGS="--prefix=\/jenkins"/' /etc/sysconfig/jenkins
sudo mkdir -p /etc/systemd/system/jenkins.service.d
sudo bash -c "echo -e \"[Service]\nEnvironment=\"JENKINS_PREFIX=/jenkins\"\n\" > /etc/systemd/system/jenkins.service.d/override.conf"
sudo systemctl restart jenkins.service || fatal_error_exit ${BASH_SOURCE}
sudo systemctl enable jenkins || fatal_error_exit ${BASH_SOURCE}
