# SETUP

## Remote

- For now, all we need is a Kafka server. For convenience, use the 'zookeeper' 
  instance in Vagrant and install Kafka 0.8.1 on it.

- You'll need to start kafka manually once ssh'ing into the server:
  > sudo bin/kafka-server-start.sh config/server.properties

## Local

- For now, develop in 'local mode'. It's easy to debug.

- Changes to the toplogy dependencies and gems require the following to be run:
 > redstorm install
 > redstorm bundle

- To run the topology:
 > bundle exec redstorm local lib/redstorm-starter/debs_topology.rb
 > bundle exec redstorm cluster lib/redstorm-starter/debs_topology.rb


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
  - ...

# Current Issues/TODOs

- Need to read more about how Kafka works.
- Revise Cassandra setup; refactor into module. Plan on hosting it on Vagrant cluster.
- Get per-house results working for Query 1.
- Write basic tests for Query 1.
- ...

- Bootstrap a proper S3 cluster and get everything working there.
- Benchmarking: figure out what to measure and what to vary.


# Cassandra Setup

- all results grouped per house under house_id
- save instantaneous load avg for plugs to compute current averages
- Cassandra running locally (OSX)

# KAFKA

*** NOTE: Kafka running on Vagrant 'zookeeper' instance ***

"Kafka does it better. By having a notion of parallelism—the partition—within the topics, Kafka is able to provide both ordering guarantees and load balancing over a pool of consumer processes. This is achieved by assigning the partitions in the topic to the consumers in the consumer group so that each partition is consumed by exactly one consumer in the group. By doing this we ensure that the consumer is the only reader of that partition and consumes the data in order. Since there are many partitions this still balances the load over many consumer instances. Note however that there cannot be more consumer instances than partitions."

- One topic. Each house is a partition? Maybe just use 'mod X' to divide them.
- Setup multiple spouts (at most, one per partition).

Start Kafka: bin/kafka-server-start.sh config/server.properties

- Setup on zookeeper vagrant instance (192.168.50.3)
- See the 'install-kafka.sh' script in storm-vagrant

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

# KAFKA Producer using jruby-kafka gem

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

# KAFKA Consumer using jruby-kafka gem

For https://github.com/joekiller/jruby-kafka gem:

  jar_dir = "/Users/dfcarney/src/ece1770/project/src/storm-vagrant/kafka-0.8.0-src/core/target/scala-2.8.0"
  include Java
  Dir.glob(File.join(jar_dir, "*.jar")) { |jar|
    $CLASSPATH << jar
  }

  require 'jruby-kafka'
  queue = SizedQueue.new(2000)

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

Example topology and its specs.

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

- run locally

```sh
$ bundle exec redstorm local lib/redstorm-starter/word_count_topology.rb
```

- run on cluster

```sh
$ bundle exec redstorm cluster lib/redstorm-starter/word_count_topology.rb
```


