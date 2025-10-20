# frozen_string_literal: true

require "securerandom"
require "singleton"
require "forwardable"

module Testcontainers
  # Custom error classes for network operations
  class NetworkError < StandardError; end
  class NetworkNotFoundError < NetworkError; end
  class NetworkAlreadyExistsError < NetworkError; end
  class NetworkInUseError < NetworkError; end

  # Lightweight wrapper for Docker networks with convenience helpers
  class Network
    extend Forwardable
    include Enumerable
    DEFAULT_DRIVER = "bridge"
    SHARED_NAME = "testcontainers-shared-network"

    # Delegate methods to the underlying Docker::Network object
    def_delegators :docker_network, :id, :json

    class << self
      # Creates and initializes a new Docker network
      #
      # @param name [String, nil] Custom network name (auto-generated if nil)
      # @param driver [String] Network driver (default: "bridge")
      # @param options [Hash] Additional Docker network options
      # @yield [Network] Optionally yields the network for block-based resource management
      # @return [Network] The created network (or result of block if given)
      #
      # @example Basic usage
      #   network = Network.create(name: "my-network")
      #
      # @example Block-based usage with automatic cleanup
      #   Network.create(name: "test-net") do |network|
      #     container.with_network(network).start
      #     # Run tests...
      #   end # network automatically closed
      def create(name: nil, driver: DEFAULT_DRIVER, options: {})
        network = new(name: name, driver: driver, options: options)
        network.create!

        if block_given?
          begin
            yield network
          ensure
            network.close
          end
        else
          network
        end
      end

      # Returns the singleton shared network instance
      #
      # @return [SharedNetwork] The shared network singleton
      def shared
        SharedNetwork.instance
      end

      # Generates a unique network name
      #
      # @return [String] A unique network name
      def generate_name
        "testcontainers-network-#{SecureRandom.uuid}"
      end
    end

    attr_reader :name, :driver, :options

    def initialize(name: nil, driver: DEFAULT_DRIVER, options: {})
      @name = name || self.class.generate_name
      @driver = driver
      @options = options
      @mutex = Mutex.new
      @docker_network = nil
    end

    # Creates the Docker network (idempotent)
    #
    # @return [self] Returns self for method chaining
    # @raise [NetworkAlreadyExistsError] if network with same name already exists
    def create!
      @mutex.synchronize do
        @docker_network ||= begin
          payload = {
            "Driver" => @driver,
            "CheckDuplicate" => true,
            "Options" => @options.empty? ? nil : @options
          }.compact

          connection = Testcontainers::DockerClient.connection
          Docker::Network.create(@name, payload, connection)
        rescue Docker::Error::ConflictError => e
          raise NetworkAlreadyExistsError, "Network '#{@name}' already exists: #{e.message}"
        end
      end

      self
    end

    # Returns the underlying Docker::Network object, creating it if necessary
    #
    # @return [Docker::Network] The Docker network object
    def docker_network
      @mutex.synchronize do
        @docker_network || create!.instance_variable_get(:@docker_network)
      end
    end

    # Checks if the network has been created
    #
    # @return [Boolean] true if network is created, false otherwise
    def created?
      !@docker_network.nil?
    end

    # Returns network information from Docker
    #
    # @return [Hash] Network information
    def info
      docker_network.json
    end

    # Iterates over containers connected to this network
    #
    # @yield [Hash] Container information for each connected container
    # @return [Enumerator] if no block is given
    #
    # @example
    #   network.each { |container| puts container["Name"] }
    #   network.map { |c| c["IPv4Address"] }
    def each(&block)
      return to_enum(:each) unless block_given?

      containers.each(&block)
    end

    # Returns containers connected to this network
    #
    # @return [Array<Hash>] Array of container information hashes
    def containers
      info.dig("Containers")&.values || []
    end

    # Closes and removes the network (idempotent)
    #
    # @param force [Boolean] If true, forcefully removes the network
    # @return [self] Returns self for method chaining
    # @raise [NetworkInUseError] if network is in use and force is false
    def close(force: false)
      return self if shared? && !force

      @mutex.synchronize do
        @docker_network&.tap do |net|
          begin
            removal_method = force ? :delete : :remove
            net.public_send(removal_method)
          rescue Docker::Error::NotFoundError
            # Swallow missing network errors so cleanup stays idempotent
          rescue Docker::Error::ConflictError, Excon::Error::Forbidden => e
            raise NetworkInUseError, "Network '#{@name}' is in use: #{e.message}"
          end
        end
      ensure
        @docker_network = nil
      end

      self
    end

    # Forcefully closes and removes the network
    #
    # @return [self] Returns self for method chaining
    def force_close
      close(force: true)
    end

    # Checks if this is the shared singleton network
    #
    # @return [Boolean] true if this is the shared network
    def shared?
      false
    end

    # Alias for close (more explicit naming)
    alias_method :destroy, :close
    alias_method :remove, :close
  end

  # Singleton shared network for multi-container test scenarios
  #
  # @example Using the shared network
  #   shared = Network.shared
  #   container1.with_network(shared, aliases: ["service1"])
  #   container2.with_network(shared, aliases: ["service2"])
  class SharedNetwork < Network
    include Singleton

    def initialize
      super(name: SHARED_NAME)
      register_cleanup
    end

    def shared?
      true
    end

    private

    def register_cleanup
      at_exit { force_close }
    end
  end

  # Backward compatibility: SHARED constant points to the singleton instance
  Network::SHARED = SharedNetwork.instance
end
