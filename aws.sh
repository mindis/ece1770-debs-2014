#!/bin/sh

cp ~/.storm/storm.yaml ./target/
bundle exec redstorm build --1.6
cp ./lib/debs/*helpers*.rb ./target/lib/debs/
bundle exec redstorm jar lib 
bundle exec redstorm cluster lib/debs/debs_topology.rb 
