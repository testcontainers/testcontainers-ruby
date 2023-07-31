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
    assert_equal({ chdir: @expected_filepath }, options)

    # Return a dummy result (can be nil or any other value you need for testing)
    [nil, nil]
  end
end

class ComposeContainerTest < TestcontainersTest

  TEST_PATH = Dir.getwd.concat("/test")
  def before_all
    super

    @container = Testcontainers::ComposeContainer.new(filepath: TEST_PATH)
    @container.start
  end

  def after_all
    #if @container&.exists?
    #  @container&.stop if @container&.running?
    #  @container&.remove
    #end

    #super
    @container.stop
  end

  def test_information_spawn
    host = @container.host_process(service: "hub", port: 4444)
    port = @container.port_process(service: "hub", port: 4444)

    assert "0.0.0.0", host
    assert 4444, port
  end


  def test_can_pull_before_build_in_spawn
    container = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, pull: true)
    host = container.host_process(service: "hub", port: 4444)
    port = container.port_process(service: "hub", port: 4444)

    assert "0.0.0.0", host
    assert 4444, port
  end
  
  def test_can_build_images_before_spawning_service_via_compose
    container = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, build: true)
    mock = Minitest::Mock.new
    mock.expect(:capture2, nil, [" docker compose -f  docker-compose.yml up -d --build", {chdir: TEST_PATH}])

    Open3.stub :capture2, proc { |cmd, opts| mock.capture2(cmd, opts) } do
      assert container.build
      container.start

    end
    mock.verify
  end

  def  test_with_specific_services
    services = ["hub","firefox","chrome"]
    container = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, services: services)
    container.start

    assert_includes container.services, "hub"
    assert_includes container.services, "firefox"
    assert_includes container.services, "chrome"
  end

  def test_with_specific_compose_files
    compose_file_name = ["docker-compose.yml","docker-compose2.yml"]
    container = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, compose_file_name: compose_file_name)

    container.start

    host = container.host_process(service: "hub", port: 4444)
    port = container.port_process(service: "hub", port: 4444)

    assert "0.0.0.0", host
    assert 4444, port

  end

  def  test_logs_for_process
    container = Testcontainers::ComposeContainer.new(filepath: TEST_PATH)
    host_name = Socket.gethostname
    url = "http://#{host_name}:4444/ui"
    container.wait_for_request(url: url)
    stdout, stderr = container.logs
    assert stdout
  end

  def test_can_pass_env_params
    compose_file_name = ["docker-compose3.yml"] 
    container = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, compose_file_name: compose_file_name, env_file: ".env.test")
    container.start
    stdout, stderr = container.run_in_container(service_name: "alpine", command: "printenv TEST_ASSERT_KEY")
    assert "successful test", stdout
    container.stop
  end
end
