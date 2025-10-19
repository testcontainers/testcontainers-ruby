# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class DockerClientTest < TestcontainersTest
  def setup
    super
    @original_env = ENV["TESTCONTAINERS_HOST"]
    ENV.delete("TESTCONTAINERS_HOST")
    Docker.reset!
  end

  def teardown
    Docker.reset!
    if @original_env
      ENV["TESTCONTAINERS_HOST"] = @original_env
    else
      ENV.delete("TESTCONTAINERS_HOST")
    end
    super
  end

  def test_connection_configures_user_agent_and_env_host
    ENV["TESTCONTAINERS_HOST"] = "tcp://example.test:2375"
    fake_connection = Object.new

    Docker::Connection.stub(:new, fake_connection) do
      connection = Testcontainers::DockerClient.connection
      assert_same fake_connection, connection
    end

    assert_equal "tcp://example.test:2375", Docker.url
    assert_equal "tc-ruby/#{Testcontainers::VERSION}", Docker.options[:headers]["User-Agent"]
  end

  def test_connection_reads_properties_file_when_env_absent
    Tempfile.create("tc-properties") do |file|
      file.write("tc.host=tcp://from-properties:1234\n")
      file.flush

      fake_connection = Object.new
      Docker::Connection.stub(:new, fake_connection) do
        Testcontainers::DockerClient.stub(:properties_path, file.path) do
          Testcontainers::DockerClient.connection
        end
      end

      assert_equal "tcp://from-properties:1234", Docker.url
    end
  end

  def test_configure_preserves_existing_connection_but_sets_user_agent
    existing_connection = Object.new
    Docker.instance_variable_set(:@connection, existing_connection)
    Docker.instance_variable_set(:@options, {})

    connection = Testcontainers::DockerClient.connection

    assert_same existing_connection, connection
    assert_equal "tc-ruby/#{Testcontainers::VERSION}", Docker.options[:headers]["User-Agent"]
  end
end
