# frozen_string_literal: true

require "test_helper"
require "pg"

class PostgresContainerTest < TestcontainersTest
  def before_all
    super

    @container = Testcontainers::PostgresContainer.new
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
    assert_equal "postgres:latest", @container.image
  end

  def test_it_supports_custom_image
    container = Testcontainers::PostgresContainer.new("mariadb:latest")
    assert_equal "mariadb:latest", container.image
  end

  def test_it_returns_the_default_port
    assert_equal 5432, @container.port
  end

  def test_it_is_configured_with_the_default_environment_variables
    assert "test", @container.get_env("POSTGRES_DATABASE")
    assert "test", @container.get_env("POSTGRES_DB")
    assert "test", @container.get_env("POSTGRES_USER")
    assert "test", @container.get_env("POSTGRES_PASSWORD")
    assert "test", @container.get_env("POSTGRES_ROOT_PASSWORD")
  end

  def test_it_has_the_default_port_mapped
    assert @container.mapped_port(5432)
  end

  def test_it_supports_custom_keyword_arguments
    container = Testcontainers::PostgresContainer.new(filesystem_binds: ["#{Dir.pwd}/custom/conf:/var/lib/postgresql/data/postgresql.conf:rw"])
    assert_equal ["#{Dir.pwd}/custom/conf:/var/lib/postgresql/data/postgresql.conf:rw"], container.filesystem_binds
  end

  def test_it_returns_the_default_database_url
    assert_equal "postgres://test:test@#{@host}:#{@port}/test", @container.database_url
  end

  def test_it_returns_the_database_url_with_custom_database
    assert_equal "postgres://test:test@#{@host}:#{@port}/foo", @container.database_url(database: "foo")
  end

  def test_it_returns_the_database_url_with_custom_protocol
    assert_equal "postgres2://test:test@#{@host}:#{@port}/test", @container.database_url(protocol: "postgres2")
  end

  def test_it_returns_the_database_url_with_custom_username
    assert_equal "postgres://foo:test@#{@host}:#{@port}/test", @container.database_url(username: "foo")
  end

  def test_it_returns_the_database_url_with_custom_password
    assert_equal "postgres://test:bar@#{@host}:#{@port}/test", @container.database_url(password: "bar")
  end

  def test_it_returns_the_database_url_with_custom_options
    assert_equal "postgres://test:test@#{@host}:#{@port}/test?useSSL=true", @container.database_url(options: {"useSSL" => "true"})
  end

  def test_it_is_reachable
    client = PG.connect(host: @host, user: "test", password: "test", port: @port, dbname: "test")
    assert_equal({"number" => "1"}, client.exec("SELECT 1 AS number").first)
  end

  def test_it_uses_wait_for_healthcheck_by_default
    expected_wait_for = Testcontainers::PostgresContainer.new(wait_for: :healthcheck).wait_for
    actual_wait_for = Testcontainers::PostgresContainer.new.wait_for

    assert_equal expected_wait_for.source_location, actual_wait_for.source_location
  end

  def test_it_uses_wait_for_healthcheck_by_default_when_port_bindings_are_specified
    expected_wait_for = Testcontainers::PostgresContainer.new(wait_for: :healthcheck).wait_for
    actual_wait_for = Testcontainers::PostgresContainer.new(port_bindings: {"5432": "15432"}).wait_for

    assert_equal expected_wait_for.source_location, actual_wait_for.source_location
  end
end
