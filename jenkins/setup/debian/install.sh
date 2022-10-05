#!/bin/sh

# install depend packages
if [ "${OS}" = "debian" ]; then
# 7はサポートされなくなっていた（2018/6/3時点） 
#  apt-get install -y openjdk-7-jre-headless
  if [ "`which java`" != "" ]; then
    apt-get remove -y openjdk-7-jre-headless
  fi
  apt-get install -y python-software-properties debconf-utils
  add-apt-repository -y ppa:webupd8team/java
  apt-get update
  echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
  apt-get install -y oracle-java8-installer
else # ubuntu1404より新しいUbuntu
  apt-get install -y openjdk-11-jre
fi

while [ "`java -version 2>&1 | grep 11.`" = "" ]
do
  echo "######################################################"
  echo "### デフォルトのJAVAがバージョン11以外になっています。"
  echo "### デフォルトのJAVAバージョンを11にして下さい。"
  echo "######################################################"
  update-alternatives --config java
done

apt-get install -y fontconfig

# download and install jenkins 
#wget -q -O - http://pkg.jenkins-ci.org/debian-stable/jenkins-ci.org.key | sudo apt-key add -
#wget -q -O - https://pkg.jenkins.io/redhat/jenkins.io.key | sudo apt-key add -
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null

#echo "deb http://pkg.jenkins-ci.org/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
#echo "deb https://pkg.jenkins.io/debian binary/" > /etc/apt/sources.list.d/jenkins.list
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get -q2 update
apt-get -y install jenkins

#sed -i 's/JENKINS_ARGS="--webroot/JENKINS_ARGS="--prefix=\/jenkins --webroot/' /etc/default/jenkins
mkdir -p /etc/systemd/system/jenkins.service.d
echo -e "[Service]\nEnvironment=\"JENKINS_PREFIX=/jenkins\"\n" > /etc/systemd/system/jenkins.service.d/override.conf

# restart jenkins
systemctl daemon-reload
service jenkins restart
