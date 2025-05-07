# frozen_string_literal: true

require "test_helper"

class NetworkTest < TestcontainersTest
  def before_all
    super
  end

  def after_all
    super
  end

  class WhenCreatingNetwork < NetworkTest
    def setup
      super
      @network = Testcontainers::Network.new_network
    end

    def teardown
      @network.close
      super
    end

    def test_it_creates_a_network
      assert_kind_of Docker::Network, @network.create
    end

    def test_it_returns_created_true_when_a_network_is_created
      @network.create

      assert @network.created?
    end

    def test_it_creates_a_network_within_docker
      refute network_exists?(@network.name)

      @network.create

      assert network_exists?(@network.name)
    end
  end

  class WhenClosingNetwork < NetworkTest
    def setup
      super
      @network = Testcontainers::Network.new_network
      @network.create
    end

    def teardown
      @network.close
      Testcontainers::Network::SHARED.force_close
      super
    end

    def test_it_removes_the_network_when_closed
      @network.create

      assert network_exists?(@network.name)

      @network.close

      refute network_exists?(@network.name)
    end

    def test_it_does_not_remove_the_shared_network
      shared_network = Testcontainers::Network::SHARED
      shared_network.create

      assert network_exists?(shared_network.name)

      shared_network.close

      assert network_exists?(shared_network.name)
    end

    def test_it_does_remove_shared_network_when_forced
      shared_network = Testcontainers::Network::SHARED
      shared_network.create

      assert network_exists?(shared_network.name)

      shared_network.force_close

      refute network_exists?(shared_network.name)
    end
  end

  class NetworkExitTest < NetworkTest

    def test_at_exit_closes_shared_network
      name = "test_exit_#{SecureRandom.uuid}"
      script = <<~RUBY
        require "testcontainers"
        Testcontainers::Network::SHARED.create
        # no explicit close – rely on at_exit
 
         $stderr.puts Testcontainers::Network::SHARED.info
         puts Testcontainers::Network::SHARED.name
      RUBY

      stdout_s, stderr_s, status = Open3.capture3("ruby", "-e", script)
      assert status.success?

      assert_match /"Name"\s+=>\s+"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"/, stderr_s

      refute network_exists?(stdout_s.chomp)
    end
  end

  def network_exists?(name)
    begin
      Docker::Network.get(name)
      true
    rescue Docker::Error::NotFoundError
      false
    end
  end

end
