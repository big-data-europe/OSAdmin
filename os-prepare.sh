#!/bin/bash

INSTALL_OPENSSH_SERVER=false
INSTALL_SSH_KEY=false
INSTALL_JDK=false
INSTALL_HADOOP=false
INSTALL_HADOOP_MASTER=false
INSTALL_HADOOP_SLAVE=false
INSTALL_MESOS=false
OPEN_PORTS=false

CONFIRM=false

while [[ $# > 1 ]]
do
key="$1"

case $key in
    -o|--openssh)
    if [ "$2" = true ]; then
      INSTALL_OPENSSH_SERVER="$2"
    fi
    shift # past argument
    ;;
    -k|--sshkeys)
    if [ "$2" = true ]; then
      INSTALL_SSH_KEY="$2"
    fi
    shift # past argument
    ;;
    -j|--jdk)
    if [ "$2" = true ]; then
      INSTALL_JDK="$2"
    fi
    shift # past argument
    ;;
    -h|--hadoop)
    if [ "$2" = true ]; then
      INSTALL_HADOOP=true
    fi
    shift
    ;;
    -m|--mesos)
    if [ "$2" = true ]; then
      INSTALL_MESOS=true;
    fi
    shift
    ;;
    --confirm)
    if [ "$2" = true ]; then
      CONFIRM="$2"
    fi
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

echo "INSTALL_OPENSSH_SERVER:$INSTALL_OPENSSH_SERVER";
echo "INSTALL_SSH_KEY:$INSTALL_SSH_KEY";
echo "INSTALL_JDK:$INSTALL_JDK";
echo "INSTALL_HADOOP:$INSTALL_HADOOP";
echo "CONFIRM:$CONFIRM"

if [ "$CONFIRM" = false ]; then
  read -r -p "OK? (Enter Y to continue the installation process) " REPLY_CONFIRM
  echo ""
  if [[ ! $REPLY_CONFIRM =~ ^[Yy]$ ]]
  then
    echo "ABORTED"
    exit 1
  else
    echo "STARTING INSTALLATION"
  fi
fi

if [ "$INSTALL_JDK" = true ]; then  
  echo "Installing JDK8"
  add-apt-repository ppa:webupd8team/java
  apt-get update
  apt-get install oracle-java8-installer
  apt-get install oracle-java8-set-default
fi


if [ "$INSTALL_OPENSSH_SERVER" = true ]; then
  aptitude -y install openssh-server  
fi

if [ "$INSTALL_HADOOP" = true ]; then
  echo "Installing Hadoop"
  echo "Creating user (hduser) and group (hadoop)"
  addgroup hadoop
  adduser -q --ingroup hadoop --disabled-password --gecos "User" hduser
  adduser hduser sudo
  sudo -u hduser -H sh -c "ssh-keygen -t rsa -b 4096 -P '' -f ~/.ssh/id_rsa"
  sudo -u hduser -H sh -c "touch ~/.ssh/authorized_keys"
  sudo -u hduser -H sh -c "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys"
  cat > /etc/sudoers.d/hduser_conf <<EOL
hduser ALL=(ALL) NOPASSWD:ALL
EOL
  passwd hduser -l
  echo "Downloading and installing hadoop"
  wget http://mirrors.gigenet.com/apache/hadoop/common/stable/hadoop-2.7.1.tar.gz
  mkdir /usr/local/hadoop
  tar xvzf hadoop-2.7.1.tar.gz -C /usr/local/hadoop  
  ln -s /usr/local/hadoop/hadoop-2.7.1 /usr/local/hadoop/current
  chown -R hduser:hadoop /usr/local/hadoop
  cat > /etc/profile.d/hadoop.sh << 'EOF'
export HADOOP_INSTALL=/usr/local/hadoop/current
export PATH=$PATH:$HADOOP_INSTALL/bin
export PATH=$PATH:$HADOOP_INSTALL/sbin
export HADOOP_MAPRED_HOME=$HADOOP_INSTALL
export HADOOP_COMMON_HOME=$HADOOP_INSTALL
export HADOOP_HDFS_HOME=$HADOOP_INSTALL
export YARN_HOME=$HADOOP_INSTALL
EOF
  source /etc/profile.d/hadoop.sh
fi

if [ "$INSTALL_MESOS" = true ]; then
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
  DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
  CODENAME=$(lsb_release -cs)
  cat > /etc/apt/sources.list.d/mesossphere.list << EOL
deb http://repos.mesosphere.io/${DISTRO} ${CODENAME} main
EOL
  apt-get -y update
  sudo apt-get -y install mesos marathon
fi
