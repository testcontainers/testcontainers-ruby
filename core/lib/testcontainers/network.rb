module Testcontainers
  class Network
    class << self
      def new_network(name: nil, driver: "bridge", options: {})
        new(name: name, driver: driver, options: options)
      end
    end

    attr_reader :name, :driver, :options

    def initialize(name: nil, driver: "bridge", options: {})
      @name = name || SecureRandom.uuid
      @driver = driver
      @options = options
      @network = nil
    end

    def create(conn = Docker.connection)
      return network if created?

      ::Testcontainers::DockerContainer.setup_docker

      @network = Docker::Network.create name, options, conn
      @created = true
      network
    end

    def created?
      @created
    end

    def close
      _close
    end

    def info
      network&.json
    end

    private

    def network
      @network
    end

    def _close
      return unless created?

      begin
        network.remove(force: true)
        @created = false
      rescue Docker::Error::NotFoundError
        # Network already removed
      end
    end

    SHARED = Testcontainers::Network.new_network

    def SHARED.close
      # prevent closing the shared network
    end

    # Should be called when the process exits
    def SHARED.force_close
      _close
    end

    at_exit do
      SHARED.force_close
    end
  end
end