bundle exec redstorm local lib/redstorm-starter/debs_topology.rb
bundle exec redstorm cluster lib/redstorm-starter/debs_topology.rb

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


