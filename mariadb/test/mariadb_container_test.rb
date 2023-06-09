# frozen_string_literal: true

require "test_helper"
require "mysql2"

class MariadbContainerTest < TestcontainersTest
  def before_all
    super

    @container = Testcontainers::MariadbContainer.new
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
    assert_equal "mariadb:latest", @container.image
  end

  def test_it_supports_custom_image
    container = Testcontainers::MariadbContainer.new("mariadb:10.10")
    assert_equal "mariadb:10.10", container.image
  end

  def test_it_returns_the_default_port
    assert_equal 3306, @container.port
  end

  def test_it_is_configured_with_the_default_environment_variables
    assert "test", @container.get_env("MARIADB_DATABASE")
    assert "test", @container.get_env("MARIADB_USER")
    assert "test", @container.get_env("MARIADB_PASSWORD")
    assert "test", @container.get_env("MARIADB_ROOT_PASSWORD")
  end

  def test_it_has_the_default_port_mapped
    assert @container.mapped_port(3306)
  end

  def test_it_supports_custom_keyword_arguments
    container = Testcontainers::MariadbContainer.new(filesystem_binds: ["#{Dir.pwd}/custom/conf:/etc/mysql/conf.d:rw"])
    assert_equal ["#{Dir.pwd}/custom/conf:/etc/mysql/conf.d:rw"], container.filesystem_binds
  end

  def test_it_returns_the_default_database_url
    assert_equal "mariadb://test:test@#{@host}:#{@port}/test", @container.database_url
  end

  def test_it_returns_the_database_url_with_custom_database
    assert_equal "mariadb://test:test@#{@host}:#{@port}/foo", @container.database_url(database: "foo")
  end

  def test_it_returns_the_database_url_with_custom_protocol
    assert_equal "mysql2://test:test@#{@host}:#{@port}/test", @container.database_url(protocol: "mysql2")
  end

  def test_it_returns_the_database_url_with_custom_username
    assert_equal "mariadb://foo:test@#{@host}:#{@port}/test", @container.database_url(username: "foo")
  end

  def test_it_returns_the_database_url_with_custom_password
    assert_equal "mariadb://test:bar@#{@host}:#{@port}/test", @container.database_url(password: "bar")
  end

  def test_it_returns_the_database_url_with_custom_options
    assert_equal "mariadb://test:test@#{@host}:#{@port}/test?useSSL=true", @container.database_url(options: {"useSSL" => "true"})
  end

  def test_it_is_reachable
    client = Mysql2::Client.new(host: @host, username: "test", password: "test", port: @port, database: "test")
    assert_equal({"number" => 1}, client.query("SELECT 1 AS number").first)
  end
end
