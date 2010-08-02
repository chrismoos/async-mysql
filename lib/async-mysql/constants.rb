module AsyncMysql
  module Constants 
    CAPABILITIES = {
      "CLIENT_LONG_PASSWORD" => 1,
      "CLIENT_FOUND_ROWS"	=> 2,
      "CLIENT_LONG_FLAG" => 4,
      "CLIENT_CONNECT_WITH_DB" => 8,
      "CLIENT_NO_SCHEMA" => 16,
      "CLIENT_COMPRESS" => 32,
      "CLIENT_ODBC" => 64,
      "CLIENT_LOCAL_FILES" => 128,
      "CLIENT_IGNORE_SPACE" => 256,
      "CLIENT_PROTOCOL_41" => 512,
      "CLIENT_INTERACTIVE" => 1024,
      "CLIENT_SSL" => 2048,
      "CLIENT_IGNORE_SIGPIPE" => 4096,
      "CLIENT_TRANSACTIONS" => 8192,
      "CLIENT_RESERVED" => 16384,
      "CLIENT_SECURE_CONNECTION" => 32768,
      "CLIENT_MULTI_STATEMENTS" => 65536,
      "CLIENT_MULTI_RESULTS" => 131072
    }
    
    FIELD_TYPES = {
      0x00 => :decimal,
      0x01 => :tiny,
      0x02 => :short,
      0x03 => :long,
      0x04 => :float,
      0x05 => :double,
      0x06 => :null,
      0x07 => :timestamp,
      0x08 => :longlong,
      0x09 => :int24,
      0x0a => :date,
      0x0b => :time,
      0x0c => :datetime,
      0x0d => :year,
      0x0e => :newdate,
      0x0f => :varchar,
      0x10 => :bit,
      0xf6 => :newdecimal,
      0xf7 => :enum,
      0xf8 => :set,
      0xf9 => :tiny_blob,
      0xfa => :medium_blob,
      0xfb => :long_blob,
      0xfc => :blob,
      0xfd => :var_string,
      0xfe => :string,
      0xff => :geometry
    }
  end
end