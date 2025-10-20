# frozen_string_literal: true

require "test_helper"

class NetworkTest < TestcontainersTest
  def test_create_creates_docker_network
    network = Testcontainers::Network.create

    assert network.created?
    docker_network = Docker::Network.get(network.name)
    assert_equal network.name, docker_network.info["Name"]
  ensure
    network&.force_close
  end

  def test_create_with_block_auto_cleanup
    network_name = nil

    Testcontainers::Network.create(name: "test-block-network") do |network|
      network_name = network.name
      assert network.created?
      docker_network = Docker::Network.get(network.name)
      assert_equal network.name, docker_network.info["Name"]
    end

    # Network should be cleaned up after block
    assert_raises(Docker::Error::NotFoundError) { Docker::Network.get(network_name) }
  end

  def test_close_is_idempotent
    network = Testcontainers::Network.create
    network.force_close

    assert_raises(Docker::Error::NotFoundError) { Docker::Network.get(network.name) }
    network.close
  ensure
    network&.force_close
  end

  def test_close_returns_self
    network = Testcontainers::Network.create

    result = network.close
    assert_same network, result
  ensure
    network&.force_close
  end

  def test_create_returns_self
    network = Testcontainers::Network.new

    result = network.create!
    assert_same network, result
  ensure
    network&.force_close
  end

  def test_shared_network_is_singleton
    shared = Testcontainers::Network.shared

    assert_same shared, Testcontainers::Network.shared
    assert shared.shared?
    assert_equal "testcontainers-shared-network", shared.name
    assert_instance_of Testcontainers::SharedNetwork, shared

    # Test backward compatibility with Network::SHARED constant
    assert_same shared, Testcontainers::Network::SHARED
  ensure
    shared.force_close
  end

  def test_shared_network_close_is_noop
    shared = Testcontainers::Network.shared
    shared.force_close

    shared.create!
    shared.close

    docker_network = Docker::Network.get(shared.name)
    assert_equal shared.name, docker_network.info["Name"]
  ensure
    shared.force_close
  end

  def test_shared_network_force_close_removes_network
    shared = Testcontainers::Network.shared
    shared.create!

    shared.force_close

    assert_raises(Docker::Error::NotFoundError) { Docker::Network.get(shared.name) }
  ensure
    shared.force_close
  end

  def test_shared_constant_backward_compatibility
    # Test that Network::SHARED works exactly like Network.shared
    shared_via_constant = Testcontainers::Network::SHARED
    shared_via_method = Testcontainers::Network.shared

    assert_same shared_via_constant, shared_via_method
    assert shared_via_constant.shared?
    assert_instance_of Testcontainers::SharedNetwork, shared_via_constant
  ensure
    shared_via_constant&.force_close
  end

  def test_method_aliases
    network = Testcontainers::Network.create

    assert_respond_to network, :destroy
    assert_respond_to network, :remove

    # Test that aliases work
    result = network.destroy
    assert_same network, result
  ensure
    network&.force_close
  end

  def test_created_predicate
    network = Testcontainers::Network.new

    refute network.created?

    network.create!

    assert network.created?
  ensure
    network&.force_close
  end

  def test_delegated_id_method
    network = Testcontainers::Network.create

    assert_respond_to network, :id
    assert_kind_of String, network.id
    refute_empty network.id
  ensure
    network&.force_close
  end

  def test_delegated_json_method
    network = Testcontainers::Network.create

    assert_respond_to network, :json
    json = network.json
    assert_kind_of Hash, json
    assert_equal network.name, json["Name"]
  ensure
    network&.force_close
  end

  def test_enumerable_containers
    network = Testcontainers::Network.create
    container = Testcontainers::DockerContainer.new("alpine:latest", command: %w[sleep 60])
      .with_network(network)
      .start

    # Test containers method
    assert_respond_to network, :containers
    containers = network.containers
    assert_kind_of Array, containers
    assert_equal 1, containers.size

    # Test each method
    network.each do |c|
      assert_kind_of Hash, c
      assert c.key?("Name")
    end

    # Test Enumerable methods
    assert_respond_to network, :map
    assert_respond_to network, :select
    names = network.map { |c| c["Name"] }
    assert_equal 1, names.size
  ensure
    container&.stop! if container&.running?
    container&.remove if container&.exists?
    network&.force_close
  end

  def test_enumerable_returns_enumerator_without_block
    network = Testcontainers::Network.create

    enumerator = network.each
    assert_instance_of Enumerator, enumerator
  ensure
    network&.force_close
  end

  def test_network_already_exists_error
    network_name = "test-duplicate-network-#{SecureRandom.hex(4)}"

    # Create network directly via Docker API first
    connection = Testcontainers::DockerClient.connection
    existing_network = Docker::Network.create(network_name, {"Driver" => "bridge"}, connection)

    # Now try to create a network with the same name using our wrapper
    network = Testcontainers::Network.new(name: network_name)

    error = assert_raises(Testcontainers::NetworkAlreadyExistsError) do
      network.create!
    end

    assert_match(/already exists/, error.message)
    assert_match(network_name, error.message)
  ensure
    # Clean up the manually created network
    begin
      existing_network&.delete
    rescue Docker::Error::NotFoundError
      # Already cleaned up
    end
  end

  def test_network_in_use_error
    network = Testcontainers::Network.create
    container = Testcontainers::DockerContainer.new("alpine:latest", command: %w[sleep 60])
      .with_network(network)
      .start

    # Try to close network while container is still running
    error = assert_raises(Testcontainers::NetworkInUseError) do
      network.close
    end

    assert_match(/in use/, error.message)
    assert_match(network.name, error.message)
  ensure
    container&.stop! if container&.running?
    container&.remove if container&.exists?
    network&.force_close
  end
end
