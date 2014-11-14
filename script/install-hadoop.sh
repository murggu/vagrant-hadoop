#!/bin/bash

#export JAVA_HOME=/usr/local/java
#export HADOOP_PREFIX=/usr/local/hadoop

HADOOP_ARCHIVE=xxx
JAVA_ARCHIVE=xxx
HADOOP_MIRROR_DOWNLOAD=http://apache.rediris.es/hadoop/common/hadoop-2.2.0/hadoop-2.2.0.tar.gz

function fileExists {
	FILE=/vagrant/config/$1
	if [ -e $FILE ]
	then
		return 0
	else
		return 1
	fi
}

function disableFirewall {
	echo "disabling firewall"
	service iptables save
	service iptables stop
	chkconfig iptables off
}

function installLocalJava {
	echo "installing oracle jdk"
	FILE=/vagrant/config/$JAVA_ARCHIVE
	tar -xzf $FILE -C /usr/local
}

function installRemoteJava {
	echo "install open jdk"
	apt-get update
	apt-get install -y openjdk-7-jdk
}

function installLocalHadoop {
	echo "install hadoop from local file"
	FILE=/vagrant/config/$HADOOP_ARCHIVE
	tar -xzf $FILE -C /usr/local
}

function installRemoteHadoop {
	echo "install hadoop from remote file"
	curl -o /home/vagrant/hadoop-2.2.0.tar.gz -O -L $HADOOP_MIRROR_DOWNLOAD
	tar -xzf /home/vagrant/hadoop-2.2.0.tar.gz -C /usr/local
}

function setupJava {
	echo "setting up java"
	if fileExists $JAVA_ARCHIVE; then
		ln -s /usr/local/jdk1.7.0_51 /usr/local/java
	else
		ln -s /usr/lib/jvm/jre /usr/local/java
	fi
}

function setupHadoop {
	echo "creating hadoop directories"
	mkdir /tmp/hadoop-namenode
	mkdir /tmp/hadoop-logs
	mkdir /tmp/hadoop-datanode
	ln -s /usr/local/hadoop-2.2.0 /usr/local/hadoop
	echo "copying over hadoop configuration files"
	cp -f /vagrant/config/core-site.xml /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/config/hdfs-site.xml /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/config/mapred-site.xml /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/config/yarn-site.xml /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/config/slaves /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/config/hadoop-env.sh /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/config/yarn-env.sh /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/config/yarn-daemon.sh /usr/local/hadoop/sbin
	cp -f /vagrant/config/mr-jobhistory-daemon.sh /usr/local/hadoop/sbin
	echo "modifying permissions on local file system"
	chown -fR vagrant /tmp/hadoop-namenode
    chown -fR vagrant /tmp/hadoop-logs
    chown -fR vagrant /tmp/hadoop-datanode
	mkdir /usr/local/hadoop-2.2.0/logs
	chown -fR vagrant /usr/local/hadoop-2.2.0/logs
}

function setupEnvVars {
	echo "creating java environment variables"
	#if fileExists $JAVA_ARCHIVE; then
	#	echo export JAVA_HOME=/usr/local/jdk1.7.0_51 >> /etc/profile.d/java.sh
	#else
	#	echo export JAVA_HOME=/usr/lib/jvm/jre >> /etc/profile.d/java.sh
	#fi
	echo export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64 >> /etc/profile.d/java.sh
	echo export PATH=\${JAVA_HOME}/bin:\${PATH} >> /etc/profile.d/java.sh

	echo "creating hadoop environment variables"
	cp -f /vagrant/config/hadoop.sh /etc/profile.d/hadoop.sh
}

function setupHadoopService {
	echo "setting up hadoop service"
	cp -f /vagrant/config/hadoop /etc/init.d/hadoop
	chmod 777 /etc/init.d/hadoop
	chkconfig --level 2345 hadoop on
}

function setupNameNode {
	echo "setting up namenode"
	/usr/local/hadoop-2.2.0/bin/hdfs namenode -format myhadoop
}

function startHadoopService {
	echo "starting hadoop service"
	service hadoop start
}

function installHadoop {
	if fileExists $HADOOP_ARCHIVE; then
		installLocalHadoop
	else
		installRemoteHadoop
	fi
}

function installJava {
	if fileExists $JAVA_ARCHIVE; then
		installLocalJava
	else
		installRemoteJava
	fi
}

function initHdfsTempDir {
	$HADOOP_PREFIX/bin/hdfs --config $HADOOP_PREFIX/etc/hadoop dfs -mkdir /tmp
	$HADOOP_PREFIX/bin/hdfs --config $HADOOP_PREFIX/etc/hadoop dfs -chmod -R 777 /tmp
}

# disableFirewall
installJava
installHadoop
# setupJava
setupHadoop
setupEnvVars
setupNameNode
setupHadoopService
startHadoopService
initHdfsTempDir