require 'eventmachine'
require 'digest/sha1'

module AsyncMysql  
  class Connection
    attr_accessor :host, :port, :username, :password, :database
    
    attr_accessor :block
    
    # @param host [String]
    # @param port [Number]
    def initialize(host, port)
      self.host = host
      self.port = port
      
      self.database = ''
      self.username = ''
      self.password = ''
      self.block = nil
    end
    
    def connect(&block)
      self.block = block
      EventMachine::connect host, port, AsyncMysql::Handler do |conn|
        conn.connection = self
      end
    end
  end
end