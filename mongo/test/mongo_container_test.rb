# frozen_string_literal: true

require "test_helper"
require "mongo"

class MongoContainerTest < TestcontainersTest
  def before_all
    super

    @container = Testcontainers::MongoContainer.new
    @container.start
    @host = @container.host
    @port = @container.first_mapped_port
  end

  def after_all
    if @container&.exists?
      @container&.stop if @container&.running?
      @container&.remove
    end

    super
  end

  def test_it_returns_the_default_image
    assert_equal "mongo:latest", @container.image
  end

  def test_it_supports_custom_image
    container = Testcontainers::MongoContainer.new("bitnami/mongodb:latest")
    assert_equal "bitnami/mongodb:latest", container.image
  end

  def test_it_returns_the_default_port
    assert_equal 27017, @container.port
  end

  def test_it_is_configured_with_the_default_environment_variables
    assert "test", @container.get_env("MONGO_DATABASE")
    assert "test", @container.get_env("MONGO_USER")
    assert "test", @container.get_env("MONGO_PASSWORD")
  end

  def test_it_has_the_default_port_mapped
    assert @container.mapped_port(27017)
  end

  def test_it_supports_custom_keyword_arguments
    container = Testcontainers::MongoContainer.new(filesystem_binds: ["#{Dir.pwd}/custom/conf:/etc/mongo/mongod.conf:rw"])
    assert_equal ["#{Dir.pwd}/custom/conf:/etc/mongo/mongod.conf:rw"], container.filesystem_binds
  end

  def test_it_returns_the_default_database_url
    assert_equal "mongodb://test:test@#{@host}:#{@port}/test", @container.mongo_url
  end

  def test_it_returns_the_database_url_with_custom_database
    assert_equal "mongodb://test:test@#{@host}:#{@port}/foo", @container.mongo_url(database: "foo")
  end

  def test_it_returns_the_database_url_with_custom_protocol
    assert_equal "mongodb2://test:test@#{@host}:#{@port}/test", @container.mongo_url(protocol: "mongodb2")
  end

  def test_it_returns_the_database_url_with_custom_username
    assert_equal "mongodb://foo:test@#{@host}:#{@port}/test", @container.mongo_url(username: "foo")
  end

  def test_it_returns_the_database_url_with_custom_password
    assert_equal "mongodb://test:bar@#{@host}:#{@port}/test", @container.mongo_url(password: "bar")
  end

  def test_it_is_reachable
    @container.wait_for_logs(/Waiting for connections/)

    client = Mongo::Client.new("mongodb://test:test@127.0.0.1:#{@port}/test", auth_source: "admin")
    client[:artists].insert_one({name: "FKA Twigs"})

    assert_equal 1, client[:artists].find(name: "FKA Twigs").count_documents
  end
end
