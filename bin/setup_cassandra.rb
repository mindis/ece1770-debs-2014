#!/usr/bin/env ruby

require 'cql'
require 'lib/debs/cassandra_helpers.rb'

include CassandraHelpers

setup_cassandra
set_base_timestamp(1377986401)


