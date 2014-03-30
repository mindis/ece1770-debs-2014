#!/bin/sh

bundle exec redstorm jar lib
bundle exec redstorm cluster lib/debs/debs_topology.rb
