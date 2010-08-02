# 
# This example shows how to run a query that gets a callback when the full result set is available.
#

require 'rubygems'
require 'async-mysql'
require 'eventmachine'
require 'logger'

# Run EventMachine
EventMachine::run do
  AsyncMysql::default_log_level = Logger::INFO
  connection = AsyncMysql::Connection.new('localhost', 3306)
  connection.username = 'root'
  connection.password = ''
  connection.database = 'mysql'
  
  connection.connect do
    puts "Connected to MySQL server."
    
    query("select * from user") do |results|
      results.each do |result|
        puts result.attributes.inspect
      end
    end
  end
end

