# Query 1 Evaluation Rationale

Throughput: two measurements:
- raw number of tuples arriving at endpoint (tuple count)
- monotonically increasing, unique number of tuples arriving at endpoint (max tuple id)

Alternative throughput measurement:
- number of predictions calculated/second
- number of novel predictions calculated/second
- latest slice predicted over time (this is equivalent to tracking the max_id, above. Discuss.)

Latency: What are we measuring? Time a tuple is submitting until we know both the plug/house predictions for it.
- approximate by assuming the endpoint is the first time something can be queried
- have the endpoint periodically query a result for a random time in the past (?)
=> attach the current timestamp to a tuple when it is dequeued
=> attach the current timestamp to tuple when it is passed to the endpoint
=> endpoint takes the difference (baseline latency)
=> separately, measure the latency of a read request vs. an unloaded Cassandra cluster for, say, 10000 random queries.

Assumptions: adding the timestamps will have negligible effect

# Workers, Executors, Threads

(From http://www.michael-noll.com/blog/2012/10/16/understanding-the-parallelism-of-a-storm-topology/#what-makes-a-running-topology-worker-processes-executors-and-tasks):

"A worker process executes a subset of a topology, and runs in its own JVM. A worker process belongs to a specific topology and may run one or more executors for one or more components (spouts or bolts) of this topology. A running topology consists of many such processes running on many machines within a Storm cluster.

An executor is a thread that is spawned by a worker process and runs within the worker’s JVM. An executor may run one or more tasks for the same component (spout or bolt). An executor always has one thread that it uses for all of its tasks, which means that tasks run serially on an executor.

A task performs the actual data processing and is run within its parent executor’s thread of execution. Each spout or bolt that you implement in your code executes as many tasks across the cluster. The number of tasks for a component is always the same throughout the lifetime of a topology, but the number of executors (threads) for a component can change over time. This means that the following condition holds true: #threads <= #tasks. By default, the number of tasks is set to be the same as the number of executors, i.e. Storm will run one task per thread (which is usually what you want anyways)."

machines -> workers -> executors -> tasks




# Problems

Vagrant: testing high throughput is problematic because: Cassandra load, 30s default timeout for tuples, ...

Cassandra: throughput heavily sensitive to Cassandra latencies

Deploying from Nimbus server is big time-saver

Maven dependencies.

Java 1.6 vs. 1.7 issues

KafkaSpout setup
KafkaSpout incompatabilities (0.7 v 0.8; no errors!)



# Future Ideas

"In contrast, bolts that do aggregations or joins may delay acking a tuple until after it has computed a result based on a bunch of tuples. Aggregations and joins will commonly multi-anchor their output tuples as well. These things fall outside the simpler pattern of IBasicBolt." (https://github.com/nathanmarz/storm/wiki/Guaranteeing-message-processing)
- For (plug) slices, only ack at the end of a slice (or at least every 30s), then emit one value to the house bolt? Saves on processing, but might increase latency.





