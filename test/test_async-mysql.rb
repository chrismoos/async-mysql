require 'helper'

require 'async-mysql'
require 'eventmachine'

class TestAsyncMysql < Test::Unit::TestCase
  def setup_connection(user, pass, database)
    @connection = AsyncMysql::Connection.new('localhost', 3306)
    @connection.username = user
    @connection.password = pass
    @connection.database = database
  end
  
  should "successfully open a connection" do
    assert_nothing_raised do
      EventMachine::run do
        setup_connection('root', '', 'mysql')
        @connection.connect do
          EM.stop
        end
      end
    end
  end
  
  should "raise an exception if the logon is denied" do
    assert_raise AsyncMysql::ConnectionException do
      EventMachine::run do
        setup_connection('root', 'someinvalidpass', 'mysql')
        @connection.connect do
          EM.stop
        end
      end
    end
  end
  
  def with_connection
    EventMachine::run do
      @connection.connect do
        yield self
      end
    end
  end
  
  context "a valid connection" do    
    setup do
      @connection = AsyncMysql::Connection.new('localhost', 3306)
      @connection.username = 'root'
      @connection.password = ''
      @connection.database = ''
    end
    
    should "be able to create a database" do
      with_connection do |conn|
        conn.query("create database if not exists async_mysql_test") do |result|
          assert_equal(:ok, result)
          EM.stop
        end
      end
    end
    
    should "return an error if query is invalid" do
      with_connection do |conn|
        conn.query("some_invalid_query") do |result|
          assert_not_nil(result[:error])
          EM.stop
        end
      end
    end
  end
  
  def create_test_table(conn, block)
    conn.query("drop table if exists users;") { }
    conn.query("create table users ( username varchar(255) null, password varchar(255) null )") do |result|
      assert_equal(:ok, result)
      block.call(conn)
    end
  end

  
  def create_test_database(&block)
    with_connection do |conn|
      conn.query("create database if not exists async_mysql_test") do |result|
        assert_equal(:ok, result)
        
        conn.query("use async_mysql_test") do |result|
          assert_equal(:ok, result)
          create_test_table(conn, block)
        end
      end
    end
  end
  

  context "with a test database" do
    setup do
      @connection = AsyncMysql::Connection.new('localhost', 3306)
      @connection.username = 'root'
      @connection.password = ''
      @connection.database = ''
    end
    
    should "create the database" do
      create_test_database do |conn|
        conn.query("insert into users (username, password) values('user', 'pass')") do |result|
          assert_equal(:ok, result)
          EM.stop
        end
      end
    end
    
    should "insert a row" do
      create_test_database do |conn|
        conn.query("insert into users (username, password) values('user', 'pass')") do |result|
          assert_equal(:ok, result)
          EM.stop
        end
      end
    end
    
    should "insert a row, then select" do
      create_test_database do |conn|
        conn.query("insert into users (username, password) values('user', 'pass')") do |result|
          assert_equal(:ok, result)
          conn.query("select * from users where username = 'user'") do |result|
            assert_equal(1, result.length)
            assert_equal('user', result[0].username)
            assert_equal('pass', result[0].password)
            EM.stop
          end
        end
      end
    end
  end
end
