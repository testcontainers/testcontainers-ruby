# frozen_string_literal: true

require "test_helper"

class DockerContainerTest < TestcontainersTest
  def before_all
    super

    @container = Testcontainers::DockerContainer.new("hello-world")
    @long_running_container = Testcontainers::DockerContainer.new("alpine:latest", command: %w[tail -f /dev/null])
    @nginx_container = Testcontainers::DockerContainer.new("nginx:alpine", exposed_ports: [80], port_bindings: {80 => 8080})
  end

  def after_all
    if @container.exists?
      @container.stop! if @container.running?
      @container.remove
    end

    if @long_running_container.exists?
      @long_running_container.stop! if @long_running_container.running?
      @long_running_container.remove
    end

    if @nginx_container.exists?
      @nginx_container.stop! if @nginx_container.running?
      @nginx_container.remove
    end

    super
  end

  def test_it_returns_the_container_image
    assert_equal "hello-world", @container.image
  end

  def test_it_returns_the_container__id
    @container.start
    refute_nil @container._id
  ensure
    @container.stop if @container.running?
  end

  def test_it_returns_the_container_name
    @container.start
    refute_nil @container.name
  ensure
    @container.stop if @container.running?
  end

  def test_it_returns_the_container_created_at
    @container.start
    refute_nil @container.created_at
  ensure
    @container.stop if @container.running?
  end

  def test_it_returns_the_container_info
    @container.start
    info = @container.info

    assert info["Id"]
    assert info["Name"]
    assert info["Created"]
    assert info["State"]
    assert info["Image"]
  ensure
    @container.stop if @container.running?
  end

  def test_it_returns_the_container_command
    assert_equal %w[tail -f /dev/null], @long_running_container.command
  end

  def test_it_returns_the_exposed_ports
    container = Testcontainers::DockerContainer.new("hello-world", exposed_ports: ["80/tcp", 8080, "8081/udp", "8082"])
    assert_equal({"80/tcp" => {}, "8080/tcp" => {}, "8081/udp" => {}, "8082/tcp" => {}}, container.exposed_ports)
  end

  def test_it_returns_the_container_port_bindings
    container = Testcontainers::DockerContainer.new("hello-world", port_bindings: {"80/tcp" => "8080", "8080" => "8081", 443 => 443})
    assert_equal({"80/tcp" => [{"HostPort" => "8080"}], "8080/tcp" => [{"HostPort" => "8081"}], "443/tcp" => [{"HostPort" => "443"}]}, container.port_bindings)
  end

  def test_it_returns_the_container_volumes
    container = Testcontainers::DockerContainer.new("hello-world", volumes: ["/tmp"])
    assert_equal({"/tmp" => {}}, container.volumes)
  end

  def test_it_returns_the_container_labels
    container = Testcontainers::DockerContainer.new("hello-world", labels: {"foo" => "bar"})
    assert_equal({"foo" => "bar"}, container.labels)
  end

  def test_it_returns_the_container_env
    container = Testcontainers::DockerContainer.new("hello-world", env: {"foo" => "bar"})
    assert_equal ["foo=bar"], container.env
  end

  def test_it_adds_a_env_variable
    container = Testcontainers::DockerContainer.new("hello-world")
    container.add_env("foo", "bar")
    container.add_env({"baz" => "qux"})
    container.add_env("quux=corge")
    container.add_env(["grault=garply"])

    assert_equal ["foo=bar", "baz=qux", "quux=corge", "grault=garply"], container.env
  end

  def test_it_adds_exposed_ports
    container = Testcontainers::DockerContainer.new("hello-world")
    container.add_exposed_ports("80/tcp", 8080, "8081/udp", "8082")

    assert_equal({"80/tcp" => {}, "8080/tcp" => {}, "8081/udp" => {}, "8082/tcp" => {}}, container.exposed_ports)
  end

  def test_it_adds_fixed_exposed_ports
    container = Testcontainers::DockerContainer.new("hello-world")
    container.add_fixed_exposed_port(80, 8080)
    container.add_fixed_exposed_port({443 => 8081})

    assert_equal({"80/tcp" => {}, "443/tcp" => {}}, container.exposed_ports)
    assert_equal({"80/tcp" => [{"HostPort" => "8080"}], "443/tcp" => [{"HostPort" => "8081"}]}, container.port_bindings)
  end

  def test_it_adds_a_volume
    container = Testcontainers::DockerContainer.new("hello-world")

    container.add_volume("/tmp")
    assert_equal({"/tmp" => {}}, container.volumes)
  end

  def test_it_adds_a_filesystem_bind
    container = Testcontainers::DockerContainer.new("hello-world")
    container.add_filesystem_bind("/tmp/docker", "/tmp", "ro")
    container.add_filesystem_bind({"/home/user" => "/root"})

    assert_equal(["/tmp/docker:/tmp:ro", "/home/user:/root:rw"], container.filesystem_binds)
  end

  def test_it_adds_filesystem_binds
    container = Testcontainers::DockerContainer.new("hello-world")
    container.add_filesystem_binds("/tmp/docker" => "/tmp", "/home/user" => "/root")

    assert_equal(["/tmp/docker:/tmp:rw", "/home/user:/root:rw"], container.filesystem_binds)
  end

  def test_it_adds_a_label
    container = Testcontainers::DockerContainer.new("hello-world")
    container.add_label("foo", "bar")

    assert_equal({"foo" => "bar"}, container.labels)
  end

  def test_it_can_be_mutated_with_the_with_method
    container = Testcontainers::DockerContainer.new("hello-world")
      .with(name: "foobar")
      .with(command: %w[tail -f /dev/null])
      .with(exposed_ports: ["80/tcp", 443])
      .with(fixed_exposed_port: {80 => 8080})
      .with(volumes: ["/tmp"])
      .with(filesystem_binds: {"/tmp/docker" => "/tmp", "/home/user" => "/root"})
      .with(labels: {"foo" => "bar"})
      .with(env: {"PATH" => "/usr/bin"})
      .with(working_dir: "/app")

    assert_equal("foobar", container.name)
    assert_equal(%w[tail -f /dev/null], container.command)
    assert_equal({"80/tcp" => {}, "443/tcp" => {}}, container.exposed_ports)
    assert_equal({"80/tcp" => [{"HostPort" => "8080"}]}, container.port_bindings)
    assert_equal({"/tmp" => {}, "/root" => {}}, container.volumes)
    assert_equal(["/tmp/docker:/tmp:rw", "/home/user:/root:rw"], container.filesystem_binds)
    assert_equal({"foo" => "bar"}, container.labels)
    assert_equal(["PATH=/usr/bin"], container.env)
    assert_equal("/app", container.working_dir)
  end

  def test_it_starts_a_container
    # we want a long-running container for this test so we can check if it's running
    @long_running_container.start
    assert @long_running_container.running?
  ensure
    @long_running_container.stop if @long_running_container.running?
  end

  def test_it_returns_if_a_container_is_not_running
    refute @container.running?
  end

  def test_it_returns_the_container_status
    @container.start
    assert_equal "exited", @container.status

    @long_running_container.start
    assert_equal "running", @long_running_container.status
  ensure
    @container.stop if @container.running?
    @long_running_container.stop if @long_running_container.running?
  end

  def test_it_stops_a_container
    # we want a long-running container for this test so we can actually stop it
    @long_running_container.start
    @long_running_container.stop
    refute @long_running_container.running?
  ensure
    @long_running_container.stop if @long_running_container.running?
  end

  def test_it_kills_a_container
    # we want a long-running container for this test so we can actually kill it
    @long_running_container.start
    @long_running_container.kill
    refute @long_running_container.running?
  ensure
    @long_running_container.stop if @long_running_container.running?
  end

  def test_it_removes_a_container
    container = Testcontainers::DockerContainer.new("hello-world")
    container.start
    container.remove
    refute container.exists?
  ensure
    container.stop if container.exists? && container.running?
    container.remove if container.exists?
  end

  def test_it_restarts_a_container
    @long_running_container.start
    @long_running_container.restart
    assert @long_running_container.running?
  ensure
    @long_running_container.stop if @long_running_container.running?
  end

  def test_it_can_be_used_with_a_block
    container = Testcontainers::DockerContainer.new("alpine:latest", command: %w[tail -f /dev/null])

    container.use do |c|
      assert_equal "running", c.status
    end

    assert_equal "exited", container.status
  ensure
    container.stop! if container.running?
    container.remove
  end

  def test_it_waits_for_logs
    @nginx_container.start

    assert @nginx_container.wait_for_logs(/start worker process/)
  ensure
    @nginx_container.stop! if @nginx_container.running?
  end

  def test_it_waits_for_http_status
    @nginx_container.start

    assert @nginx_container.wait_for_http(timeout: 10, interval: 1.0, path: "/", status: 200) # use default path and status
  ensure
    @nginx_container.stop! if @nginx_container.running?
  end

  def test_it_waits_for_tcp_port_open
    @nginx_container.start

    assert @nginx_container.wait_for_tcp_port(80, timeout: 10, interval: 1.0)
  ensure
    @nginx_container.stop! if @nginx_container.running?
  end

  def test_it_returns_the_container_logs
    @container.start
    stdout, _ = @container.logs

    assert_match(/Hello from Docker!/, stdout)
  ensure
    @container.stop if @container.running?
  end

  def test_it_executes_a_command
    @long_running_container.start
    stdout, _, exit_code = @long_running_container.exec(%w[echo Hello World])

    assert_equal "Hello World", stdout.join.chomp
    assert_equal 0, exit_code
  ensure
    @long_running_container.stop! if @long_running_container.running?
  end
end
