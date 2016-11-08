# Build the docker image
docker build -t zk-kerberos .

# Run the docker image in a container **zk-kerberos**
docker run -ti --rm -p 2181:2181 -p 88:88 -v /dev/urandom:/dev/random -h zk-kerberos --name zk-kerberos -v ~/git-repos/nifi/nifi-toolkit/nifi-toolkit-assembly/target/nifi-toolkit-1.1.0-SNAPSHOT-bin/nifi-toolkit-1.1.0-SNAPSHOT:/toolkit zk-kerberos

# add -v to mount toolkit
-v ~/git-repos/nifi/nifi-toolkit/nifi-toolkit-assembly/target/nifi-toolkit-1.1.0-SNAPSHOT-bin/nifi-toolkit-1.1.0-SNAPSHOT:/toolkit

# Create a node that is protected for the client principal
run /opt/zookeeper-3.4.6/bin/zkCli.sh
create /node content sasl:client:cdrwa

# run the zk-migrator to read the protected node from zookeeper
/toolkit/bin/zk-migrator.sh -r -z zk-kerberos:2181/node -k /opt/zookeeper-3.4.6/jaas/client-jaas.conf