# frozen_string_literal: true

require "securerandom"
module Testcontainers
  # Lightweight wrapper for Docker networks with convenience helpers
  class Network
    DEFAULT_DRIVER = "bridge"
    SHARED_NAME = "testcontainers-shared-network"

    class << self
      def new_network(name: nil, driver: DEFAULT_DRIVER, options: {})
        network = build(name: name, driver: driver, options: options)
        network.create
        network
      end

      def shared
        SHARED
      end

      def generate_name
        "testcontainers-network-#{SecureRandom.uuid}"
      end

      private

      def build(name: nil, driver: DEFAULT_DRIVER, options: {}, shared: false)
        network = new(name: name, driver: driver, options: options)
        if shared
          network.instance_variable_set(:@shared, true)
          network.send(:register_shared_cleanup)
        end
        network
      end
    end

    attr_reader :name, :driver, :options

    def initialize(name: nil, driver: DEFAULT_DRIVER, options: {})
      @shared = false
      @name = name || default_name
      @driver = driver
      @options = options
      @mutex = Mutex.new
      @docker_network = nil
    end

    def create
      @mutex.synchronize do
        return @docker_network if @docker_network

        payload = {"Driver" => @driver, "CheckDuplicate" => true}
        payload["Options"] = @options if @options && !@options.empty?
        connection = Testcontainers::DockerClient.connection
        @docker_network = Docker::Network.create(@name, payload, connection)
      end
    end

    def docker_network
      create unless @docker_network
      @docker_network
    end

    def created?
      !!@docker_network
    end

    def info
      docker_network.json
    end

    def close(force: false)
      return self if shared? && !force

      @mutex.synchronize do
        return unless @docker_network

        begin
          force ? @docker_network.delete : @docker_network.remove
        rescue Docker::Error::NotFoundError
          # Swallow missing network errors so cleanup stays idempotent
        ensure
          @docker_network = nil
        end
      end
    end

    def force_close
      close(force: true)
    end

    def shared?
      @shared
    end

    private

    def default_name
      shared? ? SHARED_NAME : self.class.generate_name
    end

    def register_shared_cleanup
      return if self.class.instance_variable_get(:@shared_cleanup_registered)

      at_exit { force_close }
      self.class.instance_variable_set(:@shared_cleanup_registered, true)
    end
  end

  Network::SHARED = Network.__send__(:build, name: Network::SHARED_NAME, shared: true)
end
