# frozen_string_literal: true

require "test_helper"

class NetworkTest < TestcontainersTest
  def test_new_network_creates_docker_network
    network = Testcontainers::Network.new_network

    assert network.created?
    docker_network = Docker::Network.get(network.name)
    assert_equal network.name, docker_network.info["Name"]
  ensure
    network&.force_close
  end

  def test_close_is_idempotent
    network = Testcontainers::Network.new_network
    network.force_close

    assert_raises(Docker::Error::NotFoundError) { Docker::Network.get(network.name) }
    network.close
  ensure
    network&.force_close
  end

  def test_shared_network_is_singleton
    shared = Testcontainers::Network::SHARED

    assert_same shared, Testcontainers::Network.shared
    assert shared.shared?
    assert_equal "testcontainers-shared-network", shared.name
  ensure
    shared.force_close
  end

  def test_shared_network_close_is_noop
    shared = Testcontainers::Network::SHARED
    shared.force_close

    shared.create
    shared.close

    docker_network = Docker::Network.get(shared.name)
    assert_equal shared.name, docker_network.info["Name"]
  ensure
    shared.force_close
  end

  def test_shared_network_force_close_removes_network
    shared = Testcontainers::Network::SHARED
    shared.create

    shared.force_close

    assert_raises(Docker::Error::NotFoundError) { Docker::Network.get(shared.name) }
  ensure
    shared.force_close
  end
end
