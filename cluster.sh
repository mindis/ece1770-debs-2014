#!/bin/sh

bundle exec redstorm jar lib/debs/debs_topology.rb
bundle exec redstorm cluster lib/debs/debs_topology.rb
