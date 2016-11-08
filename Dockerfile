from centos:6
run yum update -y

# install kerberos
run yum install -y krb5-server krb5-libs krb5-auth-dialog krb5-workstation

# install java
run yum install -y java-1.8.0-openjdk

# get and install zookeeper
run curl -O http://www-us.apache.org/dist/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz
run tar -xzf /zookeeper-3.4.6.tar.gz -C /opt

run cp /etc/krb5.conf /etc/krb5.conf.original

run cp /opt/zookeeper-3.4.6/conf/log4j.properties /opt/zookeeper-3.4.6/conf/log4j.properties.original

# expose ZooKeeper server port
expose 2181

#expose Kerberos port
expose 88

add start.sh /root/start.sh
run chmod +x /root/start.sh

# add zookeeper kerberos config
add java.env /opt/zookeeper-3.4.6/conf/java.env
run mkdir /opt/zookeeper-3.4.6/jaas
add server-jaas.conf /opt/zookeeper-3.4.6/jaas/server-jaas.conf
add client-jaas.conf /opt/zookeeper-3.4.6/jaas/client-jaas.conf

entrypoint ["/root/start.sh", "-p", "password", "-r", "ZK-KERBEROS", "-d", "zk-kerberos"]
