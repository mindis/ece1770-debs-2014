require 'rubygems'
require 'zookeeper'


def delete_subtrees(base_path)
  puts "DELETING SUBTREES AT #{base_path}"

  children = @z.get_children(:path => base_path)[:children]
  if children.empty?
    # leaf node. delete it
    @z.delete(:path => base_path)
  else
    children.each do |child|
      path = base_path + "/" + child
      delete_subtrees(path)

      result = @z.delete(:path => base_path)
      puts "DELETE: #{base_path} ==> #{result}"

    end
  end
end

@z = Zookeeper.new("192.168.50.3:2181")
children = @z.get_children(:path => "/")[:children]

# delete ["config", "admin", "brokers"] for Kafka
# rm /tmp/kafka-logs/*


Array(children & ["consumers"]).each do |child|
  path = "/" + child
  delete_subtrees(path)

end

