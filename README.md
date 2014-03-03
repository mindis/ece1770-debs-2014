redstorm install
redstorm bundle

bundle exec redstorm local lib/redstorm-starter/debs_topology.rb
bundle exec redstorm cluster lib/redstorm-starter/debs_topology.rb

# Cassandra Setup

- all results grouped per house under house_id
- save instantaneous load avg for plugs to compute current averages
- extend Query1 to different slice durations
- use TTL on Cassandra inserts (ex "USING TTL 86400")


# TODO

- get Cassandra working; results written to it and shared
- deal with discontinuities in input data
- calculate house outputs
- can we use multiple servers for the same spout? any faster?
- 

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


