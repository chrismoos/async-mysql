module AsyncMysql
  ROOT = File.expand_path(File.dirname(__FILE__))
  
  #require "#{ROOT}/fastr/extensions/string"
  
  autoload :Connection,      "#{ROOT}/async-mysql/connection"
  autoload :Column,          "#{ROOT}/async-mysql/column"
  autoload :Constants,       "#{ROOT}/async-mysql/constants"
  autoload :Row,             "#{ROOT}/async-mysql/row"
  autoload :Log,             "#{ROOT}/async-mysql/logger"
  autoload :PacketHelpers,   "#{ROOT}/async-mysql/packet_helpers"
  autoload :Security,        "#{ROOT}/async-mysql/security"
  autoload :Handler,         "#{ROOT}/async-mysql/handler"
end