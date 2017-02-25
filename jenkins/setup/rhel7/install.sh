#!/bin/sh

#wget -O cache/jenkins.rpm http://pkg.jenkins-ci.org/redhat-stable/jenkins-1.651.3-1.1.noarch.rpm
#rpm -ivh cache/jenkins.rpm
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key
yum install -y jenkins

#sed -i 's/JENKINS_JAVA_OPTIONS="-Djava.awt.headless/JENKINS_JAVA_OPTIONS="-Dhudson.diyChunking=false -Djava.awt.headless/' /etc/sysconfig/jenkins

sed -i 's/JENKINS_ARGS=""/JENKINS_ARGS="--prefix=\/jenkins"/' /etc/sysconfig/jenkins

service jenkins restart
