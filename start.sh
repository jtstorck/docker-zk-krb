#!/bin/bash

HOST_NAME="$(hostname -f)"
DOMAIN="$(hostname -f | sed 's/^[^.]\+//g' | sed 's/^\.//g')"
REALM="$(echo "$DOMAIN" | tr '[:lower:]' '[:upper:]')"
PASSWORD="BadPass#1"

printUsageAndExit() {
  echo "usage: $0 [-h] [-r REALM] [-d DOMAIN]"
  echo "       -h or --help                    print this message and exit"
  echo "       -r or --realm                   realm to use (default: $REALM)"
  echo "       -d or --domain                  domain to use (default: $DOMAIN)"
  echo "       -p or --password                password to use (default: $PASSWORD)"
  exit 1
}

# see https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash/14203146#14203146
while [[ $# -ge 1 ]]; do
  key="$1"
  case $key in
    -r|--realm)
    REALM="$2"
    shift
    ;;
    -d|--domain)
    DOMAIN="$2"
    shift
    ;;
    -p|--password)
    PASSWORD="$2"
    shift
    ;;
    -h|--help)
    printUsageAndExit
    ;;
    *)
    echo "Unknown option: $key"
    echo
    printUsageAndExit
    ;;
  esac
  shift
done

echo "HOST_NAME: $HOST_NAME"
echo "REALM:     $REALM"
echo "DOMAIN:    $DOMAIN"

cp /etc/krb5.conf.original /etc/krb5.conf
sed -i "s/kerberos\.example\.com/$HOST_NAME/g" /etc/krb5.conf
sed -i "s/EXAMPLE\.COM/$REALM/g" /etc/krb5.conf
sed -i "s/example\.com/$DOMAIN/g" /etc/krb5.conf

echo "$PASSWORD" > passwd
echo "$PASSWORD" >> passwd
kdb5_util create -s < passwd

service krb5kdc start
service kadmin start

kadmin.local -q "addprinc admin/admin" < passwd
kadmin.local -q "addprinc zookeeper/zk-kerberos" < passwd
kadmin.local -q "addprinc client/zk-kerberos" < passwd
kadmin.local -q 'addprinc -randkey -maxlife "1 second" -maxrenewlife "10 minutes" ugitest1/zk-kerberos'
kadmin.local -q 'addprinc -randkey -maxlife "1 second" -maxrenewlife "10 minutes" ugitest2/zk-kerberos'
rm -f passwd

kadmin.local -q "ktadd -k /tmp/zk.keytab zookeeper/zk-kerberos"
kadmin.local -q "ktadd -k /tmp/client.keytab client/zk-kerberos"
kadmin.local -q "ktadd -k /tmp/ugitest1.keytab ugitest1/zk-kerberos"
kadmin.local -q "ktadd -k /tmp/ugitest2.keytab ugitest2/zk-kerberos"

echo "*/admin@$REALM     *" >> /var/kerberos/krb5kdc/kadm5.acl
echo "*/zk-kerberos@$REALM     *" >> /var/kerberos/krb5kdc/kadm5.acl

service krb5kdc restart
service kadmin restart

cp /opt/zookeeper-3.4.6/conf/zoo_sample.cfg /opt/zookeeper-3.4.6/conf/zoo.cfg
echo "authProvider.1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider" >> /opt/zookeeper-3.4.6/conf/zoo.cfg
echo "requireClientAuthScheme=sasl" >> /opt/zookeeper-3.4.6/conf/zoo.cfg
echo "kerberos.removeHostFromPrincipal=true" >> /opt/zookeeper-3.4.6/conf/zoo.cfg
echo "kerberos.removeRealmFromPrincipal=true" >> /opt/zookeeper-3.4.6/conf/zoo.cfg
cp /opt/zookeeper-3.4.6/conf/log4j.properties.original /opt/zookeeper-3.4.6/conf/log4j.properties
mkdir /opt/zookeeper-3.4.6/logs
export ZOO_LOG_DIR=/opt/zookeeper-3.4.6/logs
echo "ZOO_LOG_DIR: $ZOO_LOG_DIR"
/opt/zookeeper-3.4.6/bin/zkServer.sh restart

tail -F -n+1 /var/log/k*.log /opt/zookeeper-3.4.6/logs/zookeeper.out
