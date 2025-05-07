# frozen_string_literal: true

require "test_helper"

class DockerContainerTest < TestcontainersTest
  def before_all
    super

    @container = Testcontainers::DockerContainer.new("hello-world")
    @long_running_container = Testcontainers::DockerContainer.new("alpine:latest", command: %w[tail -f /dev/null])
    @nginx_container = Testcontainers::DockerContainer.new("nginx:alpine", exposed_ports: [80], healthcheck: {test: %w[curl -f http://localhost:80]}, wait_for: [:logs, /start worker process/])
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

  def test_it_creates_an_image_with_options
    good_container = Testcontainers::DockerContainer.new("hello-world", image_create_options: {"tag" => "latest"})
    bad_container = Testcontainers::DockerContainer.new("hello-world", image_create_options: {"tag" => "nonexistent_tag"})
    good_container.start

    assert good_container.exists?
    assert_raises(Testcontainers::NotFoundError) { bad_container.start }
  ensure
    good_container.stop if good_container.exists? && good_container.running?
    good_container.remove if good_container.exists?
    bad_container.stop if bad_container.exists? && bad_container.running?
    bad_container.remove if bad_container.exists?
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

  def test_it_creates_and_returns_the_container_volumes
    container = Testcontainers::DockerContainer.new("hello-world", volumes: ["/tmp"])
    container.start
    mount_name = container.mount_names.first

    assert_equal mount_name, Docker::Volume.get(mount_name).id
    assert_equal({"/tmp" => {}}, container.volumes)
  ensure
    container.stop if container.exists? && container.running?
    container.remove({v: true}) if container.exists?
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

  def test_it_adds_exposed_ports_without_overwriting_fixed_exposed_ports
    container = Testcontainers::DockerContainer.new("hello-world")
    container.add_fixed_exposed_port(80, 8080)

    assert_equal({"80/tcp" => {}}, container.exposed_ports)
    assert_equal({"80/tcp" => [{"HostPort" => "8080"}]}, container.port_bindings)

    container.add_exposed_ports(80)
    assert_equal({"80/tcp" => {}}, container.exposed_ports)
    assert_equal({"80/tcp" => [{"HostPort" => "8080"}]}, container.port_bindings)
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

  def test_it_adds_a_wait_for_with_default
    container = Testcontainers::DockerContainer.new("hello-world", exposed_ports: [80])
    container.add_wait_for

    assert_kind_of(Proc, container.wait_for)
  end

  def test_it_adds_a_wait_for_with_proc
    container = Testcontainers::DockerContainer.new("hello-world")
    container.add_wait_for(proc { |c| sleep 1 })

    assert_kind_of(Proc, container.wait_for)
  end

  def test_it_adds_a_wait_for_with_block
    container = Testcontainers::DockerContainer.new("hello-world")
    container.add_wait_for { |c| sleep 1 }

    assert_kind_of(Proc, container.wait_for)
  end

  def test_it_adds_a_wait_for_with_hash
    container = Testcontainers::DockerContainer.new("hello-world")
    container.add_wait_for("logs", /Hello from Docker!/)

    assert_kind_of(Proc, container.wait_for)
  end

  def test_it_can_be_mutated_with_the_with_method
    container = Testcontainers::DockerContainer.new("hello-world")
      .with(name: "foobar")
      .with(command: %w[tail -f /dev/null])
      .with(entrypoint: %w[sh -c])
      .with(exposed_ports: ["80/tcp", 443])
      .with(fixed_exposed_port: {80 => 8080})
      .with(volumes: ["/tmp"])
      .with(filesystem_binds: {"/tmp/docker" => "/tmp", "/home/user" => "/root"})
      .with(labels: {"foo" => "bar"})
      .with(env: {"PATH" => "/usr/bin"})
      .with(working_dir: "/app")
      .with(wait_for: [:logs, /Hello from Docker!/])

    assert_equal("foobar", container.name)
    assert_equal(%w[tail -f /dev/null], container.command)
    assert_equal(%w[sh -c], container.entrypoint)
    assert_equal({"80/tcp" => {}, "443/tcp" => {}}, container.exposed_ports)
    assert_equal({"80/tcp" => [{"HostPort" => "8080"}], "443/tcp" => [{"HostPort" => ""}]}, container.port_bindings)
    assert_equal({"/tmp" => {}, "/root" => {}}, container.volumes)
    assert_equal(["/tmp/docker:/tmp:rw", "/home/user:/root:rw"], container.filesystem_binds)
    assert_equal({"foo" => "bar"}, container.labels)
    assert_equal(["PATH=/usr/bin"], container.env)
    assert_equal("/app", container.working_dir)
    assert_kind_of(Proc, container.wait_for)
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
    @container.wait_for_logs(/Hello from Docker!/)
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

  def test_it_removes_a_container_and_its_volumes
    container = Testcontainers::DockerContainer.new("hello-world", volumes: ["/tmp"])
    container.start
    mount_name = container.mount_names.first
    container.remove({v: true})

    refute container.exists?
    assert_raises(Docker::Error::NotFoundError) { Docker::Volume.get(mount_name) }
  ensure
    container.stop if container.exists? && container.running?
    container.remove({v: true}) if container.exists?
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

  def test_mapped_ports_with_dynamic_port
    container = Testcontainers::DockerContainer.new("nginx:alpine").with_exposed_ports(80)
    container.start
    container.wait_for_logs(/start worker process/)

    refute_nil container.mapped_port(80)
  ensure
    container&.stop! if container&.running?
    container&.remove
  end

  def test_mapped_ports_with_static_port
    container = Testcontainers::DockerContainer.new("nginx:alpine").with_fixed_exposed_port(80, 8080)
    container.start
    container.wait_for_logs(/start worker process/)

    assert_equal 8080, container.mapped_port(80)
    assert_equal 8080, container.first_mapped_port
  ensure
    container&.stop! if container&.running?
    container&.remove
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

  def test_it_waits_for_healthcheck
    @nginx_container.start

    assert @nginx_container.wait_for_healthcheck
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

  def test_it_copies_files_to_container_using_an_io_object
    @long_running_container.start
    @long_running_container.copy_file_to_container("/tmp/README.md", StringIO.new("Hello world!"))

    stdout, _, exit_code = @long_running_container.exec(%w[cat /tmp/README.md])

    assert_equal "Hello world!", stdout.join.chomp
    assert_equal 0, exit_code
  ensure
    @long_running_container.stop! if @long_running_container.running?
  end

  def test_it_copies_files_to_container_using_an_filepath
    tempfile = Tempfile.new("test")
    tempfile.write("Hello world from tempfile!")
    tempfile.close

    @long_running_container.start
    @long_running_container.copy_file_to_container("/tmp/README.md", tempfile.path)

    stdout, _, exit_code = @long_running_container.exec(%w[cat /tmp/README.md])

    assert_equal "Hello world from tempfile!", stdout.join.chomp
    assert_equal 0, exit_code
  ensure
    @long_running_container.stop! if @long_running_container.running?
    tempfile.unlink
    tempfile.close
  end

  def test_it_copies_files_from_container_using_an_io_object
    io = StringIO.new

    @long_running_container.start
    @long_running_container.copy_file_from_container("/etc/alpine-release", io)

    assert_match(/\d+\.\d+\.\d+/, io.string.chomp)
  ensure
    @long_running_container.stop! if @long_running_container.running?
  end

  def test_it_copies_files_from_container_using_a_filepath
    tempfile = Tempfile.new("test")
    tempfile.close

    @long_running_container.start
    @long_running_container.copy_file_from_container("/etc/alpine-release", tempfile.path)

    assert_match(/\d+\.\d+\.\d+/, File.read(tempfile.path).chomp)
  ensure
    @long_running_container.stop! if @long_running_container.running?
    tempfile.unlink
    tempfile.close
  end

  def test_it_connects_a_container_to_a_custom_network
    network = Testcontainers::Network.new_network

    container = Testcontainers::DockerContainer.new("hello-world").with_network(network)
    container.start

    assert container_connected?(container, container.network.name)
  ensure
    container.stop if container.exists? && container.running?
    container.remove({ v: true }) if container.exists?
    network&.close
  end

  def test_it_sets_all_aliases_for_a_container
    network = Testcontainers::Network.new_network

    container = Testcontainers::DockerContainer.new("hello-world")
                                               .with_network(network)
                                               .with_network_aliases("alias1", "alias2")

    container.start

    assert_equal ["alias1", "alias2"].sort, all_aliases(container).sort
  ensure
    container.stop if container.exists? && container.running?
    container.remove({ v: true }) if container.exists?
    network&.close
  end

  def container_connected?(container, network_name)
    networks = container.info["NetworkSettings"]["Networks"] || {}
    networks.key?(network_name)
  end

  def all_aliases(container)
    networks = container.info.dig("NetworkSettings", "Networks") || {}
    networks.values.flat_map { |cfg| cfg["Aliases"] }.compact.uniq
  end
end
