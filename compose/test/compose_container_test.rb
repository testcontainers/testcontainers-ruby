# frozen_string_literal: true

require "test_helper"
require "socket"
class Open3Stub
  def initialize(expected_up_cmd, expected_filepath)
    @expected_up_cmd = expected_up_cmd
    @expected_filepath = expected_filepath
  end

  def capture2(up_cmd, options)
    # Check if the captured arguments match the expected ones
    assert_equal @expected_up_cmd, up_cmd
    assert_equal({chdir: @expected_filepath}, options)

    # Return a dummy result (can be nil or any other value you need for testing)
    [nil, nil]
  end
end

class ComposeContainerTest < TestcontainersTest
  TEST_PATH = Dir.getwd.concat("/test")
  def before_all
    super

    @compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH)
    @compose.start
  end

  def after_all
    @compose.stop
  end

  def test_information_spawn
    host = @compose.host_process(service: "hub", port: 4444)
    port = @compose.port_process(service: "hub", port: 4444)

    assert "0.0.0.0", host
    assert 4444, port
  end

  def test_can_pull_before_build_in_spawn
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, pull: true)
    host = compose.host_process(service: "hub", port: 4444)
    port = compose.port_process(service: "hub", port: 4444)

    assert "0.0.0.0", host
    assert 4444, port
  end

  def test_can_build_images_before_spawning_service_via_compose
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, build: true)
    mock = Minitest::Mock.new
    mock.expect(:capture2, nil, [" docker compose -f  docker-compose.yml up -d --build", {chdir: TEST_PATH}])

    Open3.stub :capture2, proc { |cmd, opts| mock.capture2(cmd, opts) } do
      compose.build
      compose.start
    end
    mock.verify
    compose.stop
  end

  def test_can_verfy_specific_services
    services = ["hub", "firefox"]
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, services: services)
    mock = Minitest::Mock.new
    mock.expect(:capture2, nil, [" docker compose -f  docker-compose.yml up -d hub firefox", {chdir: TEST_PATH}])
    Open3.stub :capture2, proc { |cmd, opts| mock.capture2(cmd, opts) } do
      compose.start
    end
    mock.verify
    compose.stop
  end

  def test_with_specific_services
    services = ["hub", "firefox", "chrome"]
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, services: services)
    compose.start

    assert_includes compose.services, "hub"
    assert_includes compose.services, "firefox"
    assert_includes compose.services, "chrome"
    compose.stop
  end

  def test_with_specific_compose_files
    compose_filename = ["docker-compose.yml", "docker-compose2.yml"]
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, compose_filename: compose_filename)

    compose.start

    host = compose.host_process(service: "hub", port: 4444)
    port = compose.port_process(service: "hub", port: 4444)

    host2 = compose.host_process(service: "alpine", port: 3306)
    port2 = compose.port_process(service: "alpine", port: 3306)

    assert "0.0.0.0", host
    assert 4444, port
    assert "0.0.0.0", host2
    assert 3306, port2
    compose.stop
  end

  def test_logs_for_process
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH)
    compose.start
    ip_address = Socket.ip_address_list.find { |addr| addr.ipv4? && !addr.ipv4_loopback? }.ip_address
    url = "http://#{ip_address}:4444/ui"
    compose.wait_for_request(url: url)
    stdout, _stderr = compose.logs
    assert stdout
    compose.stop
  end

  def test_can_pass_env_params
    compose_filename = ["docker-compose3.yml"]
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, compose_filename: compose_filename, env_file: ".env.test")
    compose.start
    stdout, _stderr = compose.run_in_container(service_name: "alpine", command: "printenv TEST_ASSERT_KEY")
    assert_equal "successful test ", stdout.tr("\n", " ")
    compose.stop
  end

  def test_compose_can_wait_for_log
    compose_filename = ["docker-compose4.yml"]
    compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, compose_filename: compose_filename)
    compose.start
    stdout, _stderr = compose.logs
    assert_equal " Hello from Docker!", stdout.split("|")[3].split("\n")[0]
    compose.stop
  end
end
