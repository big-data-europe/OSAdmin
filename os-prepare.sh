#!/bin/sh

INSTALL_EPEL=true
INSTALL_SSH_KEY=true
INSTALL_UTILS=true
INSTALL_JDK=false
INSTALL_AMBARI_SERVER=false
INSTALL_BDE_ADMIN=false
OPEN_PORTS=false

CONFIRM=false
DRYRUN=true

while getopts e:u:j:a:c:k:d:p: opt; do
  case $opt in
  k)
      INSTALL_SSH_KEY=$OPTARG
      ;;
  e)
      INSTALL_EPEL=$OPTARG
      ;;
  u)
      INSTALL_UTILS=$OPTARG
      ;;
  j)
      INSTALL_JDK=$OPTARG
      ;;
  a)
      INSTALL_AMBARI_SERVER=$OPTARG
      ;;
  c)
      CONFIRM=true
      ;;
  d)
      DRYRUN=$OPTARG
      ;;
  p)
      OPEN_PORTS=$OPTARG
      ;;  
  esac
done

shift $((OPTIND - 1))

echo "INSTALL_EPEL:$INSTALL_EPEL"
echo "INSTALL_SSH_KEY:$INSTALL_SSH_KEY"
echo "INSTALL_UTILS:$INSTALL_UTILS"
echo "INSTALL_JDK:$INSTALL_JDK"
echo "INSTALL_AMBARI_SERVER:$INSTALL_AMBARI_SERVER"
echo "OPEN_PORTS:$OPEN_PORTS"
echo "CONFIRM:$CONFIRM"

if [ "$CONFIRM" = false ]; then
  read -n1 -r -p "OK? " REPLY_CONFIRM
  if [[ ! $REPLY_CONFIRM =~ ^[Yy]$ ]]
  then
    echo "ABORTED"
    exit 1
  else
    echo ""
  fi
fi

# validate IPs

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function valid_port()
{
  re='^[0-9]+$'
  if ! [[ $1 =~ $re ]] ; then
     return 1
  fi
  return 0
}

# installing epel 

if [ "$INSTALL_EPEL" = true ]; then
  echo "Installing EPEL Repository"  
  if [ "$DRYRUN" = false ]; then
    yum -y install epel-release    
  fi    
fi

# installing utils

if [ "$INSTALL_UTILS" = true ]; then
  echo "Installing utils (wget, htop, vim)"
  if [ "$DRYRUN" = false ]; then
    yum -y install wget htop vim
  fi
fi

# installing ssh keys

if [ "$INSTALL_SSH_KEY" = true ]; then
  #ssh-keygen
  echo "Creating SSH Key"
  read -n 1 -r -p "ssh-copy-id (put key into authorized keys)? (y|n):" REPLY_COPY_ID
  if [[ $REPLY_COPY_ID =~ ^[Yy]$ ]];
  then
    echo ""
    IDX=0;
    while [ $IDX -lt 1 ] || (read -n 1 -r -p "Another IP? (y|n):" REPLY_ANOTHER_IP && [[ $REPLY_ANOTHER_IP =~ ^[Yy]$ ]]);
    do
      echo ""
      read -r -p "IP:" IP
      IDX=1
      if [ ! -z $IP ]; then
        if valid_ip $IP; then
          if [ "$DRYRUN" = false ]; then
            echo "SSH-COPY-ID root@$IP"
          fi
        else
          echo "NOT VALID: $IP"
        fi
      else
        echo "Skipping empty ip"
      fi
    done
    echo ""
  else
    echo ""
  fi 
fi

# installing jdk

if [ "$INSTALL_JDK" = true ]; then  
  # see: http://tecadmin.net/install-java-8-on-centos-rhel-and-fedora/
  echo "Installing JDK8"
  if [ "$DRYRUN" = false ]; then
    cd /opt
    mkdir java
    cd java
    wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jdk-8u45-linux-x64.tar.gz"
    tar xzf jdk-8u45-linux-x64.tar.gz
    ln -s jdk1.8.0_45 current
    cd current
    alternatives --install /usr/bin/java java /opt/java/current/bin/java 2
    alternatives --set java /opt/java/current/bin/java
    alternatives --install /usr/bin/jar jar /opt/java/current/bin/jar 2
    alternatives --install /usr/bin/javac javac /opt/java/current/bin/javac 2
    alternatives --set jar /opt/java/current/bin/jar
    alternatives --set javac /opt/java/current/bin/javac

cat > /etc/profile.d/jdk.sh <<EOL
JAVA_HOME=/opt/java/current
export JAVA_HOME
EOL
  source /etc/profile.d/jdk.sh
fi

  fi

# installing ambari
if [ "$INSTALL_AMBARI_SERVER" = true ]; then
  echo "Installing Ambari"
  if [ "$DRYRUN" = false ]; then
    iptables -I INPUT -p tcp -m tcp --dport 8080 -j ACCEPT
    iptables -I INPUT -p tcp -m tcp --dport 8440 -j ACCEPT
    iptables -I INPUT -p tcp -m tcp --dport 8441 -j ACCEPT
    service iptables save  
    wget http://public-repo-1.hortonworks.com/ambari/centos6/1.x/updates/1.4.3.38/ambari.repo -P /etc/yum.repos.d/       
    yum -y install ambari-server
    cat "java.home=/opt/java/current" >> /etc/ambari-server/conf/ambari.properties
    /etc/init.d/ambari-server setup
  fi
fi

# opening ports
if [ "$OPEN_PORTS" = true ]; then
  echo "Opening firewall ports"
  IDX=0
  while [ $IDX -lt 1 ] || (read -n 1 -r -p "Another Port? (y|n):" && [[ $REPLY =~ ^[Yy]$ ]]);
  do
    echo ""
    read -r -p "PORT:" PORT
    IDX=1
    if [ ! -z $PORT ]; then
      if valid_port $PORT; then
        if [ "$DRYRUN" = false ]; then
          echo "OPEN PORT root@$PORT"
        fi
      else
        echo "NOT VALID: $PORT"
      fi
    else
      echo "Skipping empty port"
    fi
  done
  echo "DONE"
fi  
