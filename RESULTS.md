# INITIALIZATION

- Delete all Kafka topics:
  > ./kafka-topics.sh --zookeeper=54.86.78.180 --topic debs-3 --delete
  > ./kafka-topics.sh --zookeeper=54.86.78.180 --topic debs-1 --create --partitions 2 --replication 1
  > /usr/local/src/kafka/bin/kafka-topics.sh --zookeeper=54.86.78.180 --partitions 2 --replication 1 --create --topic debs-13b
  > /usr/local/src/kafka/bin/kafka-topics.sh --zookeeper=54.86.78.180 --delete --topic debs-15a



- Load Kafka, wait for server to settle

- Deploy Storm topology

- ...

# Environment

## Vagrant Setup

  1 x nimbus
  1 x zookeeper/kafka
  2 x supervisor
  1 x Cassandra

## EC2 Setup

  1 x nimbus (m1.medium)
  1 x zookeeper (m1.medium)
  1 x kafka (m1.large)
  X x supervisor (m1.large)
  3 x Cassandra (m3.large)

NIMBUS=54.86.54.174
ZOOKEEPER=54.86.78.180 (port 2181)
KAFKA=ec2-54-85-4-84.compute-1.amazonaws.com (port 9092)
CASSANDRA=54.85.123.167 (port 9042)

Steps:

1. Setup Storm cluster using storm-deploy
 - lein deploy-storm --start --commit 1bcc169f5096e03a4ae117efc65c0f9bcfa2fa22
 - lein deploy-storm --attach --name dev
 - connect to nimbus web UI on port 8080
 - test: ssh to Nimbus machine

2. setup Storm code base on Nimbus machine:
  ssh storm@NIMBUS
  sudo apt-get install -y git curl
  mkdir -p ./src
  cd src
  git clone https://github.com/dfcarney/ece1770-debs-2014.git
  curl -sSL https://get.rvm.io | bash
  source /home/storm/.rvm/scripts/rvm
  rvm install jruby-1.7.4
  cd ece1770-debs-2014/
  git checkout --track -b ec2 origin/ec2
  gem install bundler
  bundle install
  redstorm install
  redstorm bundle
  (modify the location where redstorm looks for storm.yaml)
    ...
 - setup storm.yaml
 - point debs_toplogy to kafka server
 - modify redstorm expectation for location of storm.yaml

2a. storm.yaml

storm.local.dir: "/mnt/storm"
storm.zookeeper.servers:
  - "54.86.78.180"
nimbus.host: "54.86.54.174"
drpc.servers:
  - "172.31.9.101"
storm.local.dir: "/mnt/storm"

3. Boot Kafka server
 > ssh -i dfcarney-debs.pem  ubuntu@54.86.78.180 (ensure the Firewall is open)

 - configure Kafka
  - point to Zookeeper instance
  - update "host.name" ==> bind to external/public hostname (use this in the load_kafka script)
  - update "zookeeper.connect" ==> ZOOKEEPER
  - verify supervisor nodes can connect to Kafka (port 9092)

  - attach DEBS Volume:
    sudo mkdir -p /mnt/debs
    sudo mount -o ro /dev/xvdf /mnt/debs
  - verify that can load data into topic from same server

4. Setup Cassandra
 - Ensure the instances are in the same availability zone as the Storm cluster
 - using DataStax http://www.datastax.com/documentation/cassandra/2.0/cassandra/install/installAMILaunch.html
   --clustername myDSCcluster --totalnodes 5 --version community
 - Identify master node, connect over http: on port 8888
 - Enable 512 MB cache & perform rolling restart

5. Connect Cassandra
  - verify supervisor & nimbus nodes can connect to Cassandra (on port 9042)
  - modify cassandra_helper.rb

6. Run setup_cassandra.rb script on Nimbus host


# REBALANCING

sudo storm rebalance kafka_topology -w 5 -n 3 -e debs_plug_bolt=2

