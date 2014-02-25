require 'red_storm'

# https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation

class DebsDataSpout < RedStorm::DSL::Spout

  include DebsHelpers

  output_fields :id, :timestamp, :value, :property, :plug_id, :household_id, :house_id

  configure do
    # reliable true
  end

  on_send :emit => false do
    if @data.size > 0
      tuple = @data.shift #if @data.size > 0
      unreliable_emit(*tuple)
    end
  end

  on_init do
    # id, timestamp, value, property, plug_id, household_id, house_id
    @data = %W(
1,1377986401,68.451,0,11,0,0
2,1377986401,19.927,1,11,0,0
3,1377986401,11.721,0,2,0,0
4,1377986401,9.472,1,2,0,0
5,1377986401,0,1,3,0,0
6,1377986401,0.355,0,3,0,0
7,1377986401,68.451,0,7,0,0
8,1377986401,17.743,1,7,0,0
9,1377986401,0,1,9,0,0
10,1377986401,3.701,0,9,0,0
11,1377986401,11.721,0,0,1,0
12,1377986401,21.254,1,0,1,0
13,1377986401,0,1,1,1,0
14,1377986401,3.216,0,1,1,0
15,1377986401,0,1,10,1,0
16,1377986401,0.788,0,10,1,0
17,1377986401,0,1,12,1,0
18,1377986401,0.788,0,12,1,0
19,1377986401,68.451,0,2,1,0
20,1377986401,33.291,1,2,1,0
21,1377986401,11.721,0,4,1,0
22,1377986401,18.033,1,4,1,0
23,1377986401,0,1,6,1,0
24,1377986401,3.216,0,6,1,0
25,1377986401,0,1,0,10,0
26,1377986401,3.216,0,0,10,0
27,1377986401,0,1,0,11,0
28,1377986401,0.788,0,0,11,0
29,1377986401,68.451,0,2,11,0
30,1377986401,17.367,1,2,11,0
31,1377986401,0,1,1,12,0
32,1377986401,3.216,0,1,12,0
33,1377986401,0,1,4,12,0
34,1377986401,0.788,0,4,12,0
35,1377986401,0.161,0,10,13,0
36,1377986401,0,1,10,13,0
37,1377986401,11.721,0,11,13,0
38,1377986401,15.737,1,11,13,0
39,1377986401,0,1,2,13,0
40,1377986401,3.701,0,2,13,0
41,1377986401,0,1,4,13,0
42,1377986401,0.355,0,4,13,0
43,1377986401,11.721,0,5,13,0
44,1377986401,20.34,1,5,13,0
45,1377986401,0,1,9,13,0
46,1377986401,3.216,0,9,13,0
47,1377986401,0.161,0,0,2,0
48,1377986401,0,1,0,2,0
49,1377986401,0,1,1,2,0
50,1377986401,3.216,0,1,2,0
51,1377986401,0.161,0,3,2,0
52,1377986401,0,1,3,2,0
53,1377986401,0,1,4,2,0
54,1377986401,3.701,0,4,2,0
55,1377986401,0,1,6,2,0
56,1377986401,3.216,0,6,2,0
57,1377986401,68.451,0,0,3,0
58,1377986401,40.356,1,0,3,0
59,1377986401,11.721,0,3,3,0
60,1377986401,14.593,1,3,3,0
61,1377986401,0,1,0,4,0
62,1377986401,0.788,0,0,4,0
63,1377986401,0,1,2,4,0
64,1377986401,0.788,0,2,4,0
65,1377986401,0,1,0,5,0
66,1377986401,3.701,0,0,5,0
67,1377986401,0,1,1,5,0
68,1377986401,3.701,0,1,5,0
69,1377986401,0,1,2,5,0
70,1377986401,0.788,0,2,5,0
71,1377986401,0,1,1,6,0
72,1377986401,0.355,0,1,6,0
73,1377986401,11.721,0,11,6,0
74,1377986401,30.748,1,11,6,0
75,1377986401,0,1,12,6,0
76,1377986401,3.216,0,12,6,0
77,1377986401,11.721,0,2,6,0
78,1377986401,10.977,1,2,6,0
79,1377986401,68.451,0,4,6,0
80,1377986401,69.812,1,4,6,0
81,1377986401,11.721,0,5,6,0
82,1377986401,6.147,1,5,6,0
83,1377986401,0,1,8,6,0
84,1377986401,0.355,0,8,6,0
85,1377986401,0,1,9,6,0
86,1377986401,0.788,0,9,6,0
87,1377986401,0,1,1,7,0
88,1377986401,3.701,0,1,7,0
89,1377986401,0,1,2,7,0
90,1377986401,3.701,0,2,7,0
91,1377986401,0,1,4,7,0
92,1377986401,3.701,0,4,7,0
93,1377986401,68.451,0,6,7,0
94,1377986401,16.308,1,6,7,0
95,1377986401,11.721,0,7,7,0
96,1377986401,31.633,1,7,7,0
97,1377986401,0,1,8,7,0
98,1377986401,3.216,0,8,7,0
99,1377986401,11.721,0,0,8,0
100,1377986401,9.8,1,0,8,0
).map{|f| f.split(",").map(&:to_i)} # FIXME: to_i destroys values
  end

  on_close do
    puts "CLOSING #{self.class.to_s}"
    # ...
  end

  on_ack do |msg_id|
    puts "ACK #{msg_id}"
    # ...
  end

  on_fail do |msg_id|
    puts "FAIL #{msg_id}"
    # ...
  end

  on_activate do
    puts "ACTIVATE #{msg_id}"
    # ...
  end

  on_deactivate do
    puts "DEACTIVATE #{msg_id}"
    # ...
  end

end
