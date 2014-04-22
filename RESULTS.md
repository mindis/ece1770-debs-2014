# INITIALIZATION

- Delete all Kafka topics:
  > ./kafka-topics.sh --zookeeper=192.168.50.3 --topic debs-3 --delete
  > ./kafka-topics.sh --zookeeper=192.168.50.3 --topic debs-1 --create --partitions 2 --replication 1
  >  /usr/local/src/kafka/bin/kafka-topics.sh --zookeeper=54.86.59.43 --topic debs-11 --partitions 2 --replication 1 --create



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

ZOOKEEPER=54.86.59.43 (port 2181)
KAFKA=ec2-54-86-70-160.compute-1.amazonaws.com (port 9092)
CASSANDRA=54.85.123.167 (port 9042)
NIMBUS=54.86.58.245

Steps:

1. Setup Storm cluster using storm-deploy
 - lein deploy-storm --start --commit 1bcc169f5096e03a4ae117efc65c0f9bcfa2fa22
 - lein deploy-storm --attach --name dev
 - connect to nimbus web UI on port 8080
 - test: ssh to Nimbus machine

2. setup Storm code base on Nimbus machine:
  sudo apt-get install git curl
  mkdir -p ./src
  cd src
  git clone https://github.com/dfcarney/ece1770-debs-2014.git
  curl -sSL https://get.rvm.io | bash
  source /home/storm/.rvm/scripts/rvm
  rvm install jruby-1.7.4
  cd ece1770-debs-2014/
  gem install bundler
  bundle install
  redstorm install
  redstorm bundle
  (modify the location where redstorm looks for storm.yaml)
    ...
 - setup storm.yaml
 - point debs_toplogy to kafka server

2a. storm.yaml

storm.local.dir: "/mnt/storm"
storm.zookeeper.servers:
  - "54.86.59.43"
nimbus.host: "54.86.58.245"
drpc.servers:
  - "172.31.6.88"
storm.local.dir: "/mnt/storm"

3. Boot Kafka server
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

5. Connect Cassandra
  - verify supervisor & nimbus nodes can connect to Cassandra (on port 9042)

6. Run setup_cassandra.rb script from Nimbus


# REBALANCING

sudo storm rebalance kafka_topology -w 5 -n 3 -e debs_plug_bolt=2




# TEST 1: Capacity Baseline (Vagrant)

## SETUP

  max_task_parallelism 8
  num_workers 4
  max_spout_pending 10000
  ... --> DebsPlugBolt, :parallelism => 1 (i.e. single-chain topology up to DebsPlugBolt)

  500000 tuples

## RESULTS

### Trial 1

Id, Executors, Tasks, Emitted, Transferred, Capacity (last 10m), Execute latency (ms), Executed, Process latency (ms), Acked, Failed, Last error

debs_plug_bolt  1 1 116860  0 0.995 9.151 116860  9.098 116860  0 
debs_data_bolt  1 1 1080740 1080720 0.376 0.622 720420  0.612 720420  0 
debs_household_bolt 1 1 359300  359300  0.281 1.003 359260  0.976 359280  0 
debs_house_bolt 1 1 719680  719620  0.138 0.542 359820  0.526 359820  0 
__acker 4 4 601300  601220  0.031 0.061 1505380 0.053 1505380 0880  0 

NOTE: 0.995 capacity for debs_plug_bolt

kafka_spout
  Complete latency (ms): 1265.104
  Acked: 544920
  Failed: 168780

<<< CUT OFF AT 20 minutes >>>

### Trial 2

debs_plug_bolt  1 1 123000  0 0.980 9.865 122980  9.792 122980  0 
debs_data_bolt  1 1 1211400 1211400 0.382 0.602 807240  0.582 807240  0 
debs_household_bolt 1 1 403440  403420  0.261 0.893 403420  0.839 403420  0 
debs_house_bolt 1 1 806880  806880  0.135 0.535 403440  0.526 403420  0 
__acker 4 4 668360  668300  0.022 0.053 1673080 0.050 1673100 0

kafka_spout
  Complete latency (ms): 1384.658
  Acked: 608460
  Failed: 190800

<<< CUT OFF AT 20 minutes >>>

# TEST 2: Capacity Test (Vagrant)

## Trial 1

Same as TEST 1, but DebsPlugBolt has :parallelism => 2

debs_plug_bolt  2 2 230580  0 0.966 10.362  230540  10.240  230540  0 
debs_data_bolt  1 1 707740  707700  0.220 0.670 471820  0.663 471820  0 
debs_household_bolt 1 1 235920  235900  0.175 1.011 235900  1.127 235900  0 
debs_house_bolt 1 1 471820  471800  0.095 0.624 235900  0.592 235900  0 
__acker 4 4 470760  470720  0.023 0.073 1185340 0.063 1185340 0

kafka_spout
  Complete latency (ms): 25089.783
  Acked: 431200
  Failed: 39780

## Trial 2

(rebalanced at 8m30s mark)

debs_plug_bolt  2 2 276880  0 0.984 9.567 276820  9.636 276800  0 
debs_data_bolt  1 1 843000  842960  0.261 0.666 562040  0.642 562040  0 
debs_household_bolt 1 1 280300  280240  0.161 0.842 280280  0.817 280260  0 
debs_house_bolt 1 1 560580  560560  0.106 0.692 280280  0.668 280280  0 
__acker 4 4 560340  560240  0.034 0.076 1409180 0.066 1409200 0

kafka_spout
  Complete latency (ms): 23291.285
  Acked: 521200
  Failed: 38520


# TEST 3: Capacity Test (EC2)

Similar to TEST 1, but on EC2.
4 supervisor nodes.

## Trial 1

debs_plug_bolt  1 1 135900  0 0.977 6.581 135880  6.618 135900  0 
debs_data_bolt  1 1 323260  323260  0.098 0.163 651240  0.159 651240  0 
debs_household_bolt 1 1 325700  325700  0.052 0.167 325740  0.161 325740  0 
debs_house_bolt 1 1 325840  325840  0.049 0.161 325740  0.154 325740  0

(terminated at 15 mins)

kafka_spout
  Complete latency (ms): 593.988
  Acked: 492140
  Failed: 148520

# TEST 4: 

Same as TEST 2, but DebsPlugBolt has :parallelism => 2

debs_plug_bolt  2 2 281720  0 0.991 6.359 281740  6.359 281740  0 
debs_data_bolt  1 1 285700  285700  0.101 0.184 569140  0.184 569140  0 
debs_house_bolt 1 1 284080  284080  0.054 0.204 284580  0.200 284580  0 
debs_household_bolt 1 1 284580  284580  0.040 0.158 284580  0.146 284580  0

kafka_spout
  Complete latency (ms): 16571.939
  Acked: 561200
  Failed: 7040

# TEST 5:

Same as TEST 2, but DebsPlugBolt has :parallelism => 4

  max_task_parallelism 16
  num_workers 8

debs_plug_bolt  4 4 359680  0 0.997 7.623 359720  7.595 359740  0 
debs_data_bolt  1 1 410100  410100  0.209 0.204 816800  0.197 816780  0 
debs_house_bolt 1 1 408000  408000  0.116 0.237 408400  0.227 408400  0 
debs_household_bolt 1 1 408420  408420  0.100 0.199 408380  0.179 408400  0

kafka_spout
  Complete latency (ms): 7576.891
  Acked: 784640
  Failed: 22740

## Trial 2

debs_plug_bolt  4 4 415740  0 0.957 7.577 415680  7.573 415680  0 
debs_data_bolt  1 1 465780  465780  0.193 0.205 939500  0.191 939520  0 
debs_house_bolt 1 1 474980  474980  0.108 0.222 469760  0.226 469740  0 
debs_household_bolt 1 1 469740  469740  0.097 0.192 469760  0.184 469760  0

kafka_spout 1 1 941880  941880  7377.984  892200  36500



# TEST 6:

Same as TEST 5, but with parallelism => 8

(finished 1000000 tuples at 14m00)

debs_plug_bolt  8 8 473580  0 0.967 10.197  473600  10.229  473580  0 
debs_data_bolt  1 1 1023480 1023480 0.524 0.220 2053600 0.210 2053580 0 
debs_household_bolt 1 1 476880  476880  0.498 1.698 476880  2.905 476880  0 
debs_house_bolt 1 1 1021300 1021300 0.312 0.254 1023900 0.239 1023920 0

kafka_spout 1 1 2231360 2231360 1133.405  2096100 120120


# TEST 7: Full end-to-end test

10_000_000 tuples
parallelism => 1

(terminated after 20 minutes)

- create the topic first (on the Kafka server)
 > ./bin/kafka-topics.sh --create --topic debs-7 --zookeeper  54.86.69.25:2181 --partitions 2 --replication-factor 1

debs_house_calc_bolt  1 1 169000  169000  0.990 7.722 168980  7.801 168980  0 
debs_plug_bolt  1 1 174820  174820  0.987 7.495 174820  7.486 174820  0 
debs_plug_bolt2 1 1 174840  174840  0.623 4.898 174820  4.848 174840  0 
debs_house_calc_bolt2 1 1 168820  168820  0.605 4.986 168800  5.001 168780  0 
debs_data_bolt  1 1 566160  566160  0.163 0.253 1123940 0.239 1123940 0 
debs_house_bolt 1 1 563660  563660  0.065 0.210 561920  0.207 561940  0 
debs_household_bolt 1 1 561960  561960  0.047 0.148 561920  0.146 561920  0 
debs_dummy_client_bolt  1 1 0 0 0.006 0.059 168960  0.049 168940  0

kafka_spout 1 1 1121800 1121800 1118.935  907500  206000


# TEST 8: Full production run

STARTED AT: Fri Apr 18 20:46:17 UTC 2014

 bolt DebsDataBolt, :parallelism => 1 do
 bolt DebsHouseBolt, :parallelism => 1 do
 bolt DebsHouseholdBolt, :parallelism => 2 do
 bolt DebsPlugBolt, :parallelism => 8 do
 bolt DebsPlugBolt2, :parallelism => 8 do
 bolt DebsHouseCalcBolt, :parallelism => 8 do
 bolt DebsHouseCalcBolt2, :parallelism => 8 do
 bolt DebsDummyClientBolt, :parallelism => 1 do

4 supervisors

max_task_parallelism 16
num_workers 8

10_000_000 tuples

(20 minute limit)

<<< TERMINATED WITHIN 2 minutes because load on Cassandra cluster exceeded 3.0 on one server >>>

# TEST 9: Full production run

STARTED AT: Fri Apr 18 20:46:17 UTC 2014

 bolt DebsDataBolt, :parallelism => 1 do
 bolt DebsHouseBolt, :parallelism => 1 do
 bolt DebsHouseholdBolt, :parallelism => 2 do
 bolt DebsPlugBolt, :parallelism => 4 do
 bolt DebsPlugBolt2, :parallelism => 4 do
 bolt DebsHouseCalcBolt, :parallelism => 4 do
 bolt DebsHouseCalcBolt2, :parallelism => 4 do
 bolt DebsDummyClientBolt, :parallelism => 1 do

4 supervisors

max_task_parallelism 16
num_workers 8

10_000_000 tuples

(20 minute limit) ==> 21m 24s Uptime

debs_house_calc_bolt  4 4 313100  313100  0.956 11.169  313140  11.271  313160  0 
debs_plug_bolt  4 4 330300  330300  0.956 12.046  330360  11.993  330340  0 
debs_house_calc_bolt2 4 4 312520  312520  0.534 7.097 312520  7.067 312500  0 
debs_plug_bolt2 4 4 330360  330360  0.533 6.885 330280  6.913 330300  0 
debs_data_bolt  1 1 350220  350220  0.201 0.443 696400  0.428 696380  0 
debs_house_bolt 1 1 346900  346900  0.074 0.281 348160  0.268 348180  0 
debs_household_bolt 2 2 348140  348140  0.015 0.110 348160  0.108 348140  0 
debs_dummy_client_bolt  1 1 0 0 0.014 0.101 312460  0.048 312460  0

kafka_spout 1 1 702120  702120  14400.108 620740  71880

# TEST 10: Same as test 9, but only 2 supervisors

(20 minute limit) ==> 23m 23s Uptime

debs_plug_bolt  4 4 262040  262040  0.988 16.480  262000  16.477  262000  0 
debs_house_calc_bolt  4 4 250020  250020  0.968 13.626  250000  13.709  250020  0 
debs_house_calc_bolt2 4 4 249040  249040  0.505 8.803 249100  8.690 249100  0 
debs_data_bolt  1 1 271600  271600  0.493 1.276 545000  1.233 544980  0 
debs_plug_bolt2 4 4 261940  261940  0.432 7.354 261920  7.331 261920  0 
debs_house_bolt 1 1 272640  272640  0.109 0.587 272400  0.561 272400  0 
debs_household_bolt 2 2 272460  272460  0.012 0.122 272400  0.119 272400  0 
debs_dummy_client_bolt  1 1 0 0 0.011 0.061 249160  0.049 249140  0

kafka_spout 1 1 551320  551320  22284.086 485840  57300


# TEST 11: Max config.

Let's see what's the bottleneck.

  1 x nimbus (m1.medium)
  1 x zookeeper (m1.medium)
  1 x kafka (m1.large)
  4 x supervisor (m1.large)
  5 x Cassandra (m3.large)

max_task_parallelism 8
num_workers 8
max_spout_pending 10000

Add 512 MB key_cache_size_in_mb cache on Cassandra

 bolt DebsDataBolt, :parallelism => 1
 bolt DebsPlugBolt, :parallelism => 8 (max 8)
 bolt DebsPlugBolt2, :parallelism => 8 (max 8)
 bolt DebsHouseCalcBolt, :parallelism => 8 (max 8)
 bolt DebsHouseCalcBolt2, :parallelism => 8 (max 8)
 bolt DebsDummyClientBolt, :parallelism => 1

## Trial 1

== Kafka started loading at 3m 3s, paused, 
- restarted at 15m 30s (Cassandra cache changed)
- restarted again at 31m 50s (11:00 PM) (Cassandra restart)

11:15 PM

STORM STATS

  debs_house_calc_bolt  8 8 58380 58380 1.051 101.177 58340 99.450  58340 0 
  debs_plug_bolt  8 8 85600 85600 0.772 45.136  85480 44.981  85500 0 
  debs_plug_bolt2 8 8 85480 85480 0.256 15.006  85440 54.185  85480 0 
  debs_house_calc_bolt2 8 8 58340 58340 0.176 15.840  58360 15.833  58360 0
  debs_data_bolt  1 1 118580  118580  0.098 0.477 240860  0.477 240860  0 
  debs_dummy_client_bolt  1 1 0 0 0.005 0.154 35080 0.096 35080 0

  kafka_spout
   Acked: 116220
   Failed: 109820
   Complete Latency (ms): 15162.963


CASSANDRA STATS
  Write requests: 460.01/s
  Write request latency: 1.81 ms/op
  Read requests: 176.79/s
  Read request latency: 2.56 ms/op
  OS Load (Avg): 2.23 (5.30 max)

## Trial 2

=== Kafka started loading at 0m50s uptime

STORM STATS
  debs_house_calc_bolt  8 8 343680  343540  1.038 14.292  343640  14.245  343620  0 
  debs_plug_bolt  8 8 708880  708620  0.870 15.616  354380  15.908  354380  0 
  debs_house_calc_bolt2 8 8 343740  343700  0.651 9.828 343640  9.709 343580  0 
  debs_plug_bolt2 8 8 354500  354400  0.522 9.757 354380  10.261  354400  0 
  debs_data_bolt  1 1 1125900 1125900 0.156 0.293 750620  0.507 750620  0 
  debs_dummy_client_bolt  1 1 20  0 0.051 0.131 341760  0.073 341740  0 
  __acker 8 8 693880  693780  0.010 0.028 1792060 0.023 1792060 0

  kafka_spout
   Acked: 670860
   Failed: 106520
   Complete Latency (ms): 5850.339
   10 m Latency: 3426.688


CASSANDRA STATS
  Write requests: 1990.01/s
  Write request latency: 1.36 ms/op
  Read requests: 788.05/s
  Read request latency: 1.55 ms/op
  OS Load (Avg): 1.37 (3.37 max)

## Trial 3

=== Kafka started loading at 0m25s

STORM STATS
  debs_house_calc_bolt  8 8 355740  355660  0.993 14.008  355620  14.137  355620  0 
  debs_plug_bolt  8 8 733320  733180  0.855 15.242  366620  15.271  366580  0 
  debs_house_calc_bolt2 8 8 355720  355580  0.648 9.722 355620  9.735 355600  0 
  debs_plug_bolt2 8 8 366720  366600  0.537 9.621 366620  9.561 366540  0 
  debs_data_bolt  1 1 1172000 1171980 0.178 0.262 781460  0.256 781460  0 
  debs_dummy_client_bolt  1 1 20  0 0.042 0.103 355720  0.102 355700  0 
  __acker 8 8 718300  718140  0.010 0.028 1856100 0.021 1856120 0 

  kafka_spout 1 1 1555240 1555240 5323.619  662080  105800

  10 m Latency: 3232.418 ms

CASSANDRA STATS
  Write requests: 1994.22/s
  Write request latency: 1.36 ms/op
  Read requests: 786.50/s
  Read request latency: 1.54 ms/op
  OS Load (Avg): 1.33 (3.60 max)

# TEST 12: Same as TEST 11, but rebalance 8->4 executors at start

=== Kafka loaded at 2m 29s

STORM STATS
  debs_plug_bolt  4 8 560440  560200  0.988 11.895  280100  11.929  280100  0 
  debs_house_calc_bolt  4 8 274620  274500  0.983 10.799  274380  10.761  274380  0 
  debs_house_calc_bolt2 4 8 274660  274320  0.553 6.510 274400  6.508 274420  0 
  debs_plug_bolt2 4 8 280400  280040  0.510 6.561 280180  6.568 280120  0 
  debs_data_bolt  1 1 861920  861920  0.116 0.255 574640  0.244 574640  0 
  debs_dummy_client_bolt  1 1 20  0 0.025 0.089 274340  0.066 274340  0 
  __acker 8 8 565020  564900  0.021 0.042 1424500 0.035 1424500 0 

kafka_spout 1 1 1149160 1149160 12782.670 505180  59100

10 m Latency: 12836.191 ms

CASSANDRA STATS
  Write requests: 1542.52/s
  Write request latency: 0.98 ms/op
  Read requests: 607.51/s
  Read request latency: 1.06 ms/op
  OS Load (Avg): 0.82 (2.22 max)


# TEST 13: Same as TEST 11, but executors = 4 at start, not 8

=== Kafka loaded at 0m30s

STORM STATS
  debs_plug_bolt  4 4 534960  534860  0.993 11.262  267440  11.372  267440  0 
  debs_house_calc_bolt  4 4 250500  250400  0.983 10.362  250400  10.317  250420  0 
  debs_plug_bolt2 4 4 267480  267420  0.541 6.377 267400  6.303 267420  0 
  debs_house_calc_bolt2 4 4 250680  250540  0.540 6.333 250600  6.387 250620  0 
  debs_data_bolt  1 1 915960  915920  0.126 0.248 610580  0.237 610580  0 
  debs_dummy_client_bolt  1 1 20  0 0.022 0.081 250780  0.065 250780  0 
  __acker 8 8 542200  542080  0.009 0.032 1450500 0.026 1450540 0


kafka_spout 1 1 1221300 1221300 5833.206  484160  115920

10 m Latency: 3057.068 ms

CASSANDRA STATS
  Write requests: 1483.41/s
  Write request latency: 0.94 ms/op
  Read requests: 588.08/s
  Read request latency: 1.01 ms/op
  OS Load (Avg): 0.72 (1.64 max)


# TEST 14: Same as TEST 11, but executors = 16 at start, not 8

-    max_task_parallelism 8
+    max_task_parallelism 16

=== Kafka loaded at 5m00s

STORM STATS

debs_house_calc_bolt  16  16  334780  334500  0.969 19.787  334540  19.495  334560  0 
debs_plug_bolt  16  16  692300  692080  0.826 23.537  346040  23.502  345980  0 java.lang.RuntimeException: org.jruby.exceptions.RaiseException: (QueryError) no keyspace has been specified at backtype.storm.utils.DisruptorQueue.consumeBatchToCursor(DisruptorQueue.java:90) at ba
debs_house_calc_bolt2 16  16  334820  334560  0.663 14.234  334540  14.297  334540  0 
debs_plug_bolt2 16  16  346220  345960  0.527 14.933  345960  14.947  345960  0 
debs_data_bolt  1 1 1107980 1107940 0.107 0.145 738680  0.139 738660  0 
debs_dummy_client_bolt  1 1 20  0 0.065 0.204 298900  0.169 298900  0 
__acker 8 8 671560  671440  0.011 0.029 1757980 0.023 1757940 0

kafka_spout 1 1 1521080 1521080 2906.981  609240  141580

10 m Latency: 1917.320 ms


CASSANDRA STATS
  Write requests: 2152.82/s
  Write request latency: 1.66 ms/op
  Read requests: 853.67/s
  Read request latency: 1.94 ms/op
  OS Load (Avg): 1.81 (4.15 max)

... And at 5 minutes later...

10m Latency: 1617.712 ms (and dropping)



# TEST X: Query 1, Per-query throughput & latency, 40 houses

** Testing 40/20/10 houses **

  1 x nimbus (m1.medium)
  1 x zookeeper (m1.medium)
  1 x kafka (m1.large)
  4 x supervisor (m1.large)
  5 x Cassandra (m3.large)

max_task_parallelism 8
num_workers 8
max_spout_pending 10000

 bolt DebsDataBolt, :parallelism => 1
 bolt DebsPlugBolt, :parallelism => 8 (max 8)
 bolt DebsPlugBolt2, :parallelism => 8 (max 8)
 bolt DebsHouseCalcBolt, :parallelism => 8 (max 8)
 bolt DebsHouseCalcBolt2, :parallelism => 8 (max 8)
 bolt DebsDummyClientBolt, :parallelism => 1

1. Create topic
2. Deploy topology
3. Begin loading unlimited tuples
4. Check Cassandra load
5. Rebalance at 5 minutes
6. Gather stats in 30m
7. Dump Cassandra Metrics


# TEST Y: Query 1, Per-query throughput & latency, 20 houses

# TEST Z: Query 1, Per-query throughput & latency, 10 houses

