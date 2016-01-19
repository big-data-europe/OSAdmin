#!/bin/sh

INSTALL_OPENSSH_SERVER=false
INSTALL_SSH_KEY=false
INSTALL_JDK=false
INSTALL_HADOOP=false
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
  read -n1 -r -p "OK? (Enter Y to continue the installation process) " REPLY_CONFIRM
  if [[ ! $REPLY_CONFIRM =~ ^[Yy]$ ]]
  then
    echo "ABORTED"
    exit 1
  else
    echo "STARTING INSTALLATION"
  fi
fi

if [ "$INSTALL_JDK" = true ]; then  
  # see: http://tecadmin.net/install-java-8-on-centos-rhel-and-fedora/
  echo "Installing JDK8"
  cd /opt
  mkdir java
  cd java
  wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jdk-8u45-linux-x64.tar.gz"
  tar xzf jdk-8u45-linux-x64.tar.gz
  ln -s jdk1.8.0_45 current
  cd current
  update-alternatives --install /usr/bin/java java /opt/java/current/bin/java 2
  update-alternatives --set java /opt/java/current/bin/java
  update-alternatives --install /usr/bin/jar jar /opt/java/current/bin/jar 2
  update-alternatives --install /usr/bin/javac javac /opt/java/current/bin/javac 2
  update-alternatives --set jar /opt/java/current/bin/jar
  update-alternatives --set javac /opt/java/current/bin/javac

cat > /etc/profile.d/jdk.sh <<EOL
JAVA_HOME=/opt/java/current
export JAVA_HOME
EOL
  source /etc/profile.d/jdk.sh

fi
