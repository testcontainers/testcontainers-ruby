# frozen_string_literal: true

require_relative "test_helper"
require "socket"

class Status
  def initialize(code)
    @code = code
  end

  def success?
    @code.zero?
  end
end

class ComposeContainerTest < TestcontainersTest
  TEST_PATH = __dir__

  def test_start
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH)
    mock = Minitest::Mock.new
    mock.expect(:capture3, [nil, nil, Status.new(0)], ["docker compose -f docker-compose.yml up -d", {chdir: TEST_PATH}])

    Open3.stub :capture3, proc { |cmd, opts| mock.capture3(cmd, opts) } do
      compose.start
    end

    mock.verify
  end

  def test_start_with_pull
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, pull: true)
    mock = Minitest::Mock.new
    mock.expect(:capture3, [nil, nil, Status.new(0)], ["docker compose -f docker-compose.yml pull", {chdir: TEST_PATH}])
    mock.expect(:capture3, [nil, nil, Status.new(0)], ["docker compose -f docker-compose.yml up -d", {chdir: TEST_PATH}])

    Open3.stub :capture3, proc { |cmd, opts| mock.capture3(cmd, opts) } do
      compose.start
    end

    mock.verify
  end

  def test_start_with_build
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, build: true)
    mock = Minitest::Mock.new
    mock.expect(:capture3, [nil, nil, Status.new(0)], ["docker compose -f docker-compose.yml up -d --build", {chdir: TEST_PATH}])

    Open3.stub :capture3, proc { |cmd, opts| mock.capture3(cmd, opts) } do
      compose.start
    end

    mock.verify
  end

  def test_start_with_services
    services = ["hub", "firefox"]
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, services: services)
    mock = Minitest::Mock.new
    mock.expect(:capture3, [nil, nil, Status.new(0)], ["docker compose -f docker-compose.yml up -d hub firefox", {chdir: TEST_PATH}])

    Open3.stub :capture3, proc { |cmd, opts| mock.capture3(cmd, opts) } do
      compose.start
    end

    mock.verify
  end

  def test_stop
    mock = Minitest::Mock.new
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH)
    compose.instance_variable_set(:@_container_started, true)

    mock.expect(:capture3, [nil, nil, Status.new(0)], ["docker compose -f docker-compose.yml down -v", {chdir: TEST_PATH}])

    Open3.stub :capture3, proc { |cmd, opts| mock.capture3(cmd, opts) } do
      compose.stop
    end

    mock.verify
  end

  def test_running?
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH)
    compose.instance_variable_set(:@_container_started, true)

    assert compose.running?
  end

  def test_exited?
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH)

    assert compose.exited?
  end

  def test_service_port
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH)
    compose.instance_variable_set(:@_container_started, true)

    mock = Minitest::Mock.new
    mock.expect(:capture3, ["0.0.0.0:4444", nil, Status.new(0)], ["docker compose -f docker-compose.yml port hub 4444", {chdir: TEST_PATH}])

    Open3.stub :capture3, proc { |cmd, opts| mock.capture3(cmd, opts) } do
      assert_equal "4444", compose.service_port(service: "hub", port: 4444)
    end

    mock.verify
  end

  def test_service_host
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH)
    compose.instance_variable_set(:@_container_started, true)

    mock = Minitest::Mock.new
    mock.expect(:capture3, ["0.0.0.0:4444", nil, Status.new(0)], ["docker compose -f docker-compose.yml port hub 4444", {chdir: TEST_PATH}])

    Open3.stub :capture3, proc { |cmd, opts| mock.capture3(cmd, opts) } do
      assert_equal "0.0.0.0", compose.service_host(service: "hub", port: 4444)
    end

    mock.verify
  end

  def test_multi_compose_files_support
    compose_filenames = ["docker-compose.yml", "docker-compose3.yml"]
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, compose_filenames: compose_filenames)
    compose.start

    assert_equal "4444", compose.service_port(service: "hub", port: 4444)
    assert_equal "3306", compose.service_port(service: "alpine", port: 3306)
  ensure
    compose.stop
  end

  def test_env_file_support
    compose_filename = ["docker-compose3.yml"]
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, compose_filenames: compose_filename, env_file: ".env.test")
    compose.start

    stdout, _stderr, _ = compose.exec(service_name: "alpine", command: "printenv TEST_ASSERT_KEY")
    assert_match %r{successful test}, stdout
  ensure
    compose.stop
  end

  def test_logs
    compose_filename = ["docker-compose2.yml"]
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, compose_filenames: compose_filename)
    compose.start

    assert_match %r{Hello from Docker!}, compose.logs
  ensure
    compose.stop
  end

  def test_wait_for_logs
    compose_filename = ["docker-compose2.yml"]
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, compose_filenames: compose_filename)
    compose.start

    assert compose.wait_for_logs(matcher: %r{Hello from Docker!})
  ensure
    compose.stop
  end

  def test_wait_for_http
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH)
    compose.start
    ip_address = Socket.ip_address_list.find { |addr| addr.ipv4? && !addr.ipv4_loopback? }.ip_address
    url = "http://#{ip_address}:4444/ui"
    assert compose.wait_for_http(url: url)
  ensure
    compose.stop
  end

  def test_wait_for_tcp_port
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH)
    compose.start
    ip_address = Socket.ip_address_list.find { |addr| addr.ipv4? && !addr.ipv4_loopback? }.ip_address
    assert compose.wait_for_tcp_port(host: ip_address, port: 4444)
  ensure
    compose.stop
  end
end
