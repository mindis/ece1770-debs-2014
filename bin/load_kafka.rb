#!/usr/bin/env ruby

jar_dir = "/Users/dfcarney/src/ece1770/project/src/storm-vagrant/kafka-0.8.0-src/core/target/scala-2.8.0"
include Java
Dir.glob(File.join(jar_dir, "*.jar")) { |jar|
  $CLASSPATH << jar
}

require 'jruby-kafka'
require 'zlib'

topic = "debs"
producer_options = {:zk_connect=>"192.168.50.3:2181", :topic_id=>topic, :broker_list=>"192.168.50.3:9092"} 
producer = Kafka::Producer.new(producer_options)
producer.connect()


filepath = "/Users/dfcarney/src/ece1770/project/sorted.csv.gz"
fd = File::open(filepath, "r")
gz = Zlib::GzipReader.new(fd)

# id, timestamp, value, property, plug_id, household_id, house_id
@data = []
count = 0
max_entries = 100
while(gz.lineno < max_entries) 
  line =  gz.readline.strip
  id, timestamp, value, property, plug_id, household_id, house_id = line.split(",")
  datum = [id.to_i, timestamp.to_i, value.to_f, property.to_i, plug_id.to_i, household_id.to_i, house_id.to_i]
  producer.sendMsg(topic, id, line)
  count = count + 1
  puts "Loaded #{count} entries." if ((count * 10) % max_entries == 0)
end
true
