require 'rubygems'
require 'test/unit'
require 'bundler'

require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'async-mysql'

Bundler.setup

class Test::Unit::TestCase
  def em_setup 
    EM.run do
      yield
      EM.stop
    end
  end
end
