require 'eventmachine'

module AsyncMysql
  class Handler < EventMachine::Connection
    include AsyncMysql::Log
    include AsyncMysql::PacketHelpers

    module State
      HANDSHAKE_INIT = 1
      HANDSHAKE_INIT_ACK = 2
      COMMAND = 3
    end
    
    module SubState
      WAIT_RESULT_SET_HEADER = 4
      WAIT_RESULT_SET_FIELDS = 5
      WAIT_RESULT_SET_DATA = 6
      WAIT_RESULT_SET_END = 7
    end
    
    PACKET_HEADER_SIZE = 4
    
    # The connection associated with this handler.
    # @return [AsyncMysql::Connection]
    attr_accessor :connection

    # Information about the server
    attr_accessor :server_information
    #attr_accessor :protocol_version, :server_version, :server_language, :server_capabilities, :thread_id, :server_status

    # List of current columns for this request
    attr_accessor :result_columns

    def initialize(*args)
      @wait_buffer = ""
      @requests = []
      @packet_number = 1
      super
    end
    
    # Sends a query and calls the block as the results become available.
    # @param str [String] The query string
    # @param &block [Proc] The block that will be called when a result arrives.
    # @return [void]
    def query_streaming(str, &block)
      do_query(str, true, &block)
    end
    
    # Sends a query and calls the block when all the results are available.
    # @param str [String] The query string
    # @param &block [Proc] The block that will be called when the result set is finished.
    # @return [void]
    def query(str, &block)
      do_query(str, false, &block)
    end
    
    # Returns a human readable string of the server's capabilities.
    # @return [String]
    def server_capabilities
      capabilities = []
      Constants::CAPABILITIES.each do |k,v|
        capabilities << k if @server_information[:server_capabilities] & v != 0
      end
      return capabilities.join(", ")
    end
    
    # Returns true if the server has the given capability. See AsyncMysql::Constants::CAPABILITIES
    # @return [Boolean]
    def server_has_capability?(name)
      return (@server_information[:server_capabilities] & Constants::CAPABILITIES[name]) != 0
    end
    
    private
    
    def do_query(str, streaming, &block)
      @packet_number = 0
      send_command_packet(3, str)
      @substate = SubState::WAIT_RESULT_SET_HEADER
      @requests << {:streaming => streaming, :callback => block}
    end
    
    # Connection State
    
    def post_init
      log.debug "connected to server"
      @state = State::HANDSHAKE_INIT
      @server_information = {}
    end
    
    def unbind
      log.debug "disconnected"
    end


    
    
    def send_packet(data)
      size = [data.length].pack('V')
      
      pck = [size, @packet_number, data].pack('a3Ca*')
      @packet_number += 1
      self.send_data(pck)
    end
    
    def process_handshake_init_ack(packet)
      resultType = packet[0]
      
      case resultType
      when 0
        log.debug "handshake_init(): ok"
        @state = State::COMMAND
        self.instance_eval(&self.connection.block) if self.connection.block
      when 0xff
        error_info = packet.unpack('CvCa5Z*')
        
        errno = error_info[1]
        sqlstate = error_info[3]
        msg = error_info[4]
        
        log.debug "handshake_init(): error: #{errno}, sqlstate: #{sqlstate}, msg: #{msg}"
      else
        log.debug "handshake_init(): unknown result type"
      end
    end

    def send_client_authentication(scramble)
      items = []
      items << (@server_information[:server_capabilities] ^ Constants::CAPABILITIES["CLIENT_COMPRESS"])
      items << 65535
      items << @server_information[:server_language]
      items << self.connection.username

      items << length_binary(AsyncMysql::Security::scramble_password(self.connection.password, scramble))
      items << self.connection.database
      
      client_auth = items.pack('VVCx23Z*a*Z*')
      send_packet(client_auth)
      
      @state = State::HANDSHAKE_INIT_ACK
    end
    
    def process_handshake_init(packet)
      init_packet = packet.unpack('CZ*Va8avCva13Z*')
      @server_information = {
        :protocol_version => init_packet[0],
        :server_version => init_packet[1],
        :thread_id => init_packet[2],
        :server_capabilities => init_packet[5],
        :server_language => init_packet[6],
        :server_status => init_packet[7]
      }
      
      scramble_buff = init_packet[3] + init_packet[9]

      log.debug "handshake_init(): info: #{@server_information.inspect}"
      log.debug "server capabilities: #{server_capabilities}"
      
      raise Exception.new("Server doesn't support protocol 4.1") if not server_has_capability? "CLIENT_PROTOCOL_41"
      
      send_client_authentication(scramble_buff)
    end
    
    
    
    def process_packet(packet)
      log.debug "process_packet(): state[#{@state}], pck: #{packet.inspect}"
      
      case @state
      when State::HANDSHAKE_INIT
        process_handshake_init(packet)
      when State::HANDSHAKE_INIT_ACK
        process_handshake_init_ack(packet)
      when State::COMMAND
        process_command(packet)
      end
    end
    
    def receive_data(data)
      @wait_buffer += data
      
      run = true
      while run
        run = parse_packet
      end
      
    end
    
    def parse_packet
      # Return if there isn't a packet header yet.
      return false if @wait_buffer.length < PACKET_HEADER_SIZE
      
      # Parse the packet header
      header = (@wait_buffer[0..2] + "\0" + @wait_buffer[3].chr).unpack("VC")
      packetLength = header[0]
      packetNumber = header[1]

      # See if we have enough data for a packet
      if (@wait_buffer.length - PACKET_HEADER_SIZE) >= packetLength
        log.debug "Received packet, size: #{packetLength}, number: #{packetNumber}"
        
        process_packet(@wait_buffer[PACKET_HEADER_SIZE..(packetLength + PACKET_HEADER_SIZE)])
        
        @wait_buffer.slice!(0..((PACKET_HEADER_SIZE + packetLength - 1)))

        return true
      end
      
      return false
    end
    
    #### Commands
    
    def process_field(packet)
      column = AsyncMysql::Column.new
      
      catalog, packet = get_length_binary(packet)
      db, packet = get_length_binary(packet)
      table, packet = get_length_binary(packet)
      org_table, packet = get_length_binary(packet)
      name, packet = get_length_binary(packet)
      org_name, packet = get_length_binary(packet)
      other_info = packet.unpack('CvVCvCC2a*')
      
      charsetnr = other_info[1]
      length = other_info[2]
      type = other_info[3]
      flags = other_info[4]
      decimal = other_info[5]
      
      column.catalog = catalog
      column.db = db
      column.table = table
      column.org_table = table
      column.name = name
      column.org_name = org_name
      column.charsetnr = charsetnr
      column.length = length
      column.type = type
      column.flags = flags
      column.decimal = decimal

      self.result_columns << column
    end
    
    def process_row(packet)
      row = AsyncMysql::Row.new
      row.columns = self.result_columns

      self.result_columns.each do |column|
        value, packet = get_length_binary(packet)
        row.data << value
      end
 
      if current_request[:streaming]
        current_request[:callback].call(row)
      else
        current_request[:results] << row
      end
    end
    
    def current_request
      @requests[0]
    end
    
    def process_command(packet)
      resultType = packet[0]
      case resultType
      when 0
        log.debug "process_command(): ok"
      when 0xff
        error_info = packet.unpack('CvCa5Z*')
        
        errno = error_info[1]
        sqlstate = error_info[3]
        msg = error_info[4]
        
        log.debug "process_command(): error: #{errno}, sqlstate: #{sqlstate}, msg: #{msg}"
      else
        # Process a result set packet
        case @substate 
        when SubState::WAIT_RESULT_SET_HEADER
          @substate = SubState::WAIT_RESULT_SET_FIELDS
          self.result_columns = []
          
        when SubState::WAIT_RESULT_SET_FIELDS
          if resultType == 0xfe
            @substate = SubState::WAIT_RESULT_SET_DATA
            
            current_request[:results] = []
            
          else 
            process_field(packet)
          end
        when SubState::WAIT_RESULT_SET_DATA
          if resultType == 0xfe
            @substate = nil
            
            # We aren't streaming the results, pass the whole result set
            if not current_request[:streaming]
              current_request[:callback].call(current_request[:results])
            end
            
            @requests = @requests[1..(@requests.length - 1)]
            
            @substate = SubState::WAIT_RESULT_SET_HEADER if not @requests[0].nil?
              
          else 
            process_row(packet)
          end
        end
      end
    end
    
    def send_command_packet(cmd, data)
      send_packet([cmd, data].pack('Ca*'))
    end
  end
end