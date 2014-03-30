# DEBS Grand Challenge 2014

- http://www.cse.iitb.ac.in/debs2014/?page_id=42

# SETUP

## AWS

- TODO: Use storm-deploy (https://github.com/nathanmarz/storm-deploy)
 - See http://blog.safaribooksonline.com/2013/12/27/storm-deploy-amazon-ec2/

## Vagrant

- If there's a problem with Vagrant (on OSX), first try:
 - sudo /Library/StartupItems/VirtualBox/VirtualBox restart

- For cluster-based testing, use storm-vagrant (https://github.com/ptgoetz/storm-vagrant)
  - I updated it to use 'precise64' and storm-0.9.0.1, 2 GB of RAM per instance

- We additionally need is a Kafka server. For convenience, use the 'zookeeper' 
  instance in Vagrant and install Kafka 0.8.1 on it. There's a storm-vagrant
  'install-kafka.sh' script for this.

- You'll need to start kafka manually once ssh'ing into the server:
  > sudo bin/kafka-server-start.sh config/server.properties

- Install Kafka
 - modify host.name to point to the public IP
 - start the server manually

- Nimbus here: http://192.168.50.4:8080/

- modify 'rpc_address' setting in /etc/cassandra/cassandra.yaml and ensure that clients can connect to Cassandra

- setup the Cassandra DB manually using the 'bin/setup_cassandra.rb' script

- To run the topology:
 > bundle exec redstorm cluster lib/debs/debs_topology.rb


## Local

- For now, develop in 'local mode' with a Vagrant-baseed Kafka server. It's easy to debug.

- Changes to the toplogy dependencies and gems require the following to be run:
 > redstorm install
 > redstorm bundle

- To run the topology:
 > bundle exec redstorm jar lib/debs/debs_topology.rb 
 > bundle exec redstorm cluster lib/debs/debs_topology.rb

# TIMELINE

- [< March 17, 2014]
  - Bootstrapped Vagrant cluster using storm-vagrant
  - Abandoned pure Java & Closure programming in favour of JRuby. Much thanks to 'redstorm' maintainer.
  - Got basic Query 1 stream working for one time slice, plug-only. Storing results in memory.
  - Added Cassandra server (running locally) to save predicted and final results.
  - (more stuff that I'll fill in later)

- [March 17, 2014] Spent a day debugging Kafka setup. Trying to get a proper spout working with Storm. Troublesome.

- [March 18, 2014]
  - Finally got Kafka spout working. Needed to switch to storm-kafka-0.8-plus (0.4.0).
  - Refactor Cassandra, Plug, and other stuff into modules
  - Get per-house results working for Query 1.

- [March 19, 2014]
  - Wrote some basic tests for Query 1 (test.rb, using test1.csv and test2.csv)
  - Tests discovered one bug with house load calc. Easily fixed.
  - Bootstrap Vagrant cluster for storm
   - upgrade instances to use Ruby 1.9.3, Java 1.7
   - getting weird errors when submitting to storm cluster. 
    - Verify Java/Ruby versions
    - configure ~/.storm/storm.yml
    - Attempt to build & submit from Ubuntu vagrant 'nimbus' instance
     - apt-get update
     - apt-get upgrade
     - apt-get install curl ant git-core 
     - install Cassandra (http://java.dzone.com/articles/installing-apache-cassandra)
     - TODO Figure out how to start/daemonize Cassandra on startup
     - install RVM
     - install JRuby 1.7.4 (> rvm install jruby-1.7.4)
     - check out this source code
     - gem install bundler
     - bundle install
     - redstorm install
     - redstorm bundle
     - test locally (DONE)
     - TODO test submitting to cluster

- [March 21, 2014]
  - Finished setting up test Vagrant cluster:
    - Cassandra running on 'zookeeper' node
    - Kafka running on 'nimbus' node
    - Increase RAM to 2 GB for each of the 4 systems
    - Installed Oracle Java7
    - Debugged various issues with 'redstorm' gem (modules not loaded in jar, etc)
  - Initial tests show that Cassandra single node is under very heavy load
  - 

- [March 22, 2014]
  - Experimented with running Cassandra in a separate Vagrant instance/cluster
  - Experimented with running Cassandra direclty on my laptop; 
    - reconfigure Vagrant cluster to use Bridged mode
    - update Vagrantfile
    - update /etc/hosts files
    - modify my cassandra.yml and firewall settings so that Vagrant can connect to Cassandra
  - Rebootstrap cluster w/ 5 machines (original 4 + Cassandra) and do some testing.

- [March 30, 2014]
  - Get rid of "ALLOW FILTERING" clause on some Cassandra queries



- NEXT: Get working on AWS


# Current Issues/TODOs

- Bootstrap a proper AWS cluster and get everything working there.
- Benchmarking: figure out what to measure and what to vary.

- Need to read more about how Kafka works.
- Don't calculate house results all the time. Can we do this lazily or on demand?
- Fix 'invalidate_future_results' method
- More testing/validating results.


- KAFKA: partition the input data? Setup multiple spouts (at most, one per partition)?
  - One topic. Each house is a partition? Maybe just use 'mod X' to divide them?

# Cassandra Setup

- all results grouped per house under house_id
- save instantaneous load avg for plugs to compute current averages
- Cassandra running locally (OSX)

# KAFKA

*** NOTE: Kafka running on Vagrant 'zookeeper' instance ***

"Kafka does it better. By having a notion of parallelism—the partition—within the topics, Kafka is able to provide both ordering guarantees and load balancing over a pool of consumer processes. This is achieved by assigning the partitions in the topic to the consumers in the consumer group so that each partition is consumed by exactly one consumer in the group. By doing this we ensure that the consumer is the only reader of that partition and consumes the data in order. Since there are many partitions t#his still balances the load over many consumer instances. Note however that there cannot be more consumer instances than partitions."

---

See https://kafka.apache.org/documentation.html#quickstart

Start the server:
  > bin/kafka-server-start.sh config/server.properties

Create a topic:
  > bin/kafka-create-topic.sh --zookeeper localhost:2181 --replica 1 --partition 1 --topic test

We can now see that topic if we run the list topic command:
  > bin/kafka-list-topic.sh --zookeeper localhost:2181

Send some messages:
  > bin/kafka-console-producer.sh --broker-list localhost:9092 --topic test

# jruby-kafka gem

    https://github.com/joekiller/jruby-kafka

## Simple KAFKA Producer

    jar_dir = "/Users/dfcarney/src/ece1770/project/src/storm-vagrant/kafka-0.8.0-src/core/target/scala-2.8.0"
    include Java
    Dir.glob(File.join(jar_dir, "*.jar")) { |jar|
      $CLASSPATH << jar
    }

    require 'jruby-kafka'

    producer_options = {:zk_connect=>"192.168.50.3:2181", :topic_id=>"test", :broker_list=>"192.168.50.3:9092"} 
    producer = Kafka::Producer.new(producer_options)
    producer.connect()

    topic = "testtopic"
    key = "1"
    message = "This is a test"
    producer.sendMsg(topic, key, message)

## Simple KAFKA Consumer

    jar_dir = "/Users/dfcarney/src/ece1770/project/src/storm-vagrant/kafka-0.8.0-src/core/target/scala-2.8.0"
    include Java
    Dir.glob(File.join(jar_dir, "*.jar")) { |jar|
      $CLASSPATH << jar
    }

    require 'jruby-kafka'
    queue = SizedQueue.new(20)

    consumer_options = {:zk_connect=>"192.168.50.3:2181", :topic_id=>"testtopic", :broker_list=>"192.168.50.3:9092", :group_id => "blorky"} 

    group = Kafka::Group.new(consumer_options)
    num_threads = 1
    group.run(num_threads, queue)
    Java::JavaLang::Thread.sleep 3000

    # just gets first 20 things & prints out
    until queue.empty?
      puts(queue.pop)
    end

    group.shutdown()

# Casandra DEBUG

    require 'cql'
    @store = Cql::Client.connect(hosts: ['127.0.0.1'])
    @store.use('measurements')
    q1 = "SElECT COUNT(*) FROM InstantaneousPlugLoads"
    @store.execute(q1)

    q2 = "SElECT COUNT(*) FROM AveragePlugLoads"
    @store.execute(q2)

# redstorm-starter

This project is based on the contents of https://github.com/colinsurprenant/redstorm-starter

## Related Docs

- https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation

- https://github.com/nathanmarz/storm/wiki/Concepts

## Dependencies

Tested with:
- [RedStorm](https://github.com/colinsurprenant/redstorm) >= 0.6.6
- JRuby 1.7.4
- [Storm](https://github.com/nathanmarz/storm/) 0.9.0-wip16.

## Setup

```sh
$ bundle install
$ bundle exec redstorm install
$ bundle exec rake spec
```

# MISC STUFF

- Installing Scala:
 - https://gist.github.com/visenger/5496675
 - http://yurisubach.com/blog/2013/10/22/how-to-install-scala-and-sbt-to-ubuntu-12-dot-04-lts/

- Ubuntu/Cassandra/Kafka/Storm walkthrough
 - http://www.kashifshah.net/blog/2013/11/cassandra-kafka-storm-virtualbox-ubuntu-server-13-10/

- Installing ruby1.9.3 on Ubuntu
 - http://leonard.io/blog/2012/05/installing-ruby-1-9-3-on-ubuntu-12-04-precise-pengolin/

