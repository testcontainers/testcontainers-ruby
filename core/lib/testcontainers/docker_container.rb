module Testcontainers
  # The DockerContainer class is used to manage Docker containers.
  # It provides an interface to create, start, stop, and manipulate containers
  # using the Docker API.
  #
  # @attr name [String] the container's name
  # @attr image [String] the container's image name
  # @attr command [Array<String>, nil] the command to run in the container
  # @attr exposed_ports [Hash, nil] a hash mapping exposed container ports to an empty hash (used for Docker API compatibility)
  # @attr port_bindings [Hash, nil] a hash mapping container ports to host port bindings (used for Docker API compatibility)
  # @attr volumes [Hash, nil] a hash mapping volume paths in the container to an empty hash (used for Docker API compatibility)
  # @attr filesystem_binds [Array<String>, nil] an array of strings representing bind mounts from the host to the container
  # @attr env [Array<String>, nil] an array of environment variables for the container in the format KEY=VALUE
  # @attr labels [Hash, nil] a hash of labels to be applied to the container
  # @attr working_dir [String, nil] the working directory for the container
  # @attr logger [Logger] a logger instance for the container
  # @attr_reader _container [Docker::Container, nil] the underlying Docker::Container object
  # @attr_reader _id [String, nil] the container's ID
  class DockerContainer
    attr_accessor :name, :image, :command, :exposed_ports, :port_bindings, :volumes, :filesystem_binds, :env, :labels, :working_dir
    attr_accessor :logger
    attr_reader :_container, :_id

    # Initializes a new DockerContainer instance.
    #
    # @param image [String] the container's image name
    # @param command [Array<String>, nil] the command to run in the container
    # @param name [String, nil] the container's name
    # @param exposed_ports [Hash, Array<String>, nil] a hash or an array of exposed container ports
    # @param port_bindings [Hash, Array<String>, nil] a hash or an array of container ports to host port bindings
    # @param volumes [Hash, Array<String>, nil] a hash or an array of volume paths in the container
    # @param filesystem_binds [Array<String>, Hash, nil] an array of strings or a hash representing bind mounts from the host to the container
    # @param env [Array<String>, Hash, nil] an array or a hash of environment variables for the container in the format KEY=VALUE
    # @param labels [Hash, nil] a hash of labels to be applied to the container
    # @param working_dir [String, nil] the working directory for the container
    # @param logger [Logger] a logger instance for the container
    def initialize(image, command: nil, name: nil, exposed_ports: nil, port_bindings: nil, volumes: nil, filesystem_binds: nil, env: nil,
      labels: nil, working_dir: nil, logger: Testcontainers.logger)

      @image = image
      @command = command
      @name = name
      @exposed_ports = add_exposed_ports(exposed_ports) if exposed_ports
      @port_bindings = add_fixed_exposed_ports(port_bindings) if port_bindings
      @volumes = add_volumes(volumes) if volumes
      @env = add_env(env) if env
      @filesystem_binds = add_filesystem_binds(filesystem_binds) if filesystem_binds
      @labels = add_labels(labels) if labels
      @working_dir = working_dir
      @logger = logger
      @_container = nil
      @_id = nil
      @_created_at = nil
    end

    # Add environment variables to the container configuration.
    #
    # @param env_or_key [String, Hash, Array] The environment variable(s) to add.
    #   - When passing a Hash, the keys and values represent the variable names and values.
    #   - When passing an Array, each element should be a String in the format "KEY=VALUE".
    #   - When passing a String, it should be in the format "KEY=VALUE" or a key when a value is also provided.
    # @param value [String, nil] The value for the environment variable if env_or_key is a key (String).
    # @return [Array<String>] The updated list of environment variables in the format "KEY=VALUE".
    def add_env(env_or_key, value = nil)
      @env ||= []
      new_env = process_env_input(env_or_key, value)
      @env.concat(new_env)
      @env
    end

    # Add an exposed port to the container configuration.
    #
    # @param port [String, Integer] The port to expose in the format "port/protocol" or as an integer.
    # @return [Hash] The updated list of exposed ports.
    def add_exposed_port(port)
      port = normalize_port(port)
      @exposed_ports ||= {}
      @port_bindings ||= {}
      @exposed_ports[port] = {}
      @port_bindings[port] = [{"HostPort" => ""}]
      @exposed_ports
    end

    # Add multiple exposed ports to the container configuration.
    #
    # @param ports [Array<String, Integer>] The list of ports to expose.
    # @return [Hash] The updated list of exposed ports
    def add_exposed_ports(*ports)
      ports = ports.first if ports.first.is_a?(Array)

      ports.each do |port|
        add_exposed_port(port)
      end
      @exposed_ports
    end

    # Add a fixed exposed port to the container configuration.
    #
    # @param container_port [String, Integer, Hash] The container port in the format "port/protocol" or as an integer.
    #   When passing a Hash, it should contain a single key-value pair with the container port as the key and the host port as the value.
    # @param host_port [Integer, nil] The host port to bind the container port to.
    # @return [Hash] The updated list of port bindings.
    def add_fixed_exposed_port(container_port, host_port = nil)
      if container_port.is_a?(Hash)
        container_port, host_port = container_port.first
      end

      container_port = normalize_port(container_port)
      @exposed_ports ||= {}
      @port_bindings ||= {}
      @exposed_ports[container_port] = {}
      @port_bindings[container_port] = [{"HostPort" => host_port.to_s}]
      @port_bindings
    end

    # Add multiple fixed exposed ports to the container configuration.
    #
    # @param port_mappings [Hash] The list of container ports and host ports to bind them to.
    # @return [Hash] The updated list of port bindings.
    def add_fixed_exposed_ports(port_mappings = {})
      port_mappings.each do |container_port, host_port|
        add_fixed_exposed_port(container_port, host_port)
      end
      @port_bindings
    end

    # Add a volume to the container configuration.
    #
    # @param volume [String] The volume to add.
    # @return [Hash] The updated list of volumes.
    def add_volume(volume)
      @volumes ||= {}
      @volumes[volume] = {}
      @volumes
    end

    # Add multiple volumes to the container configuration.
    #
    # @param volumes [Array<String>] The list of volumes to add.
    # @return [Hash] The updated list of volumes.
    def add_volumes(volumes = [])
      volumes = normalize_volumes(volumes)
      @volumes ||= {}
      @volumes.merge!(volumes)
      @volumes
    end

    # Add a filesystem bind to the container configuration.
    #
    # @param host_or_hash [String, Hash] The host path or a Hash with a single key-value pair representing the host and container paths.
    # @param container_path [String, nil] The container path if host_or_hash is a String.
    # @param mode [String] The access mode for the bind ("rw" for read-write, "ro" for read-only). Default is "rw".
    # @return [Array<String>] The updated list of filesystem binds in the format "host_path:container_path:mode".
    def add_filesystem_bind(host_or_hash, container_path = nil, mode = "rw")
      @filesystem_binds ||= []

      if host_or_hash.is_a?(Hash)
        host_path, container_path = host_or_hash.first
      elsif host_or_hash.is_a?(String)
        if container_path
          host_path = host_or_hash
        else
          host_path, container_path, mode = host_or_hash.split(":")
          mode ||= "rw"
        end
      else
        raise ArgumentError, "Invalid input format for add_filesystem_bind"
      end

      @filesystem_binds << "#{host_path}:#{container_path}:#{mode}"
      add_volume(container_path)
      @filesystem_binds
    end

    # Add multiple filesystem binds to the container configuration.
    #
    # @param filesystem_binds [Array<String>, Array<Array<String>>, Hash] The list of filesystem binds.
    # @return [Array<String>] The updated list of filesystem binds in the format "host_path:container_path:mode".
    def add_filesystem_binds(filesystem_binds)
      @filesystem_binds ||= []
      binds = normalize_filesystem_binds(filesystem_binds)
      binds.each do |bind|
        add_filesystem_bind(*bind)
      end
      @filesystem_binds
    end

    # Add a label to the container configuration.
    #
    # @param label [String] The label to add.
    # @param value [String] The value of the label.
    # @return [Hash] The updated list of labels.
    def add_label(label, value)
      @labels ||= {}
      @labels[label] = value
      @labels
    end

    # Add multiple labels to the container configuration.
    #
    # @param labels [Hash] The labels to add.
    # @return [Hash] The updated list of labels.
    def add_labels(labels)
      @labels ||= {}
      @labels.merge!(labels)
      @labels
    end

    # Set options for the container configuration using "with_" methods.
    #
    # @param options [Hash] A hash of options where keys correspond to "with_" methods and values are the arguments for those methods.
    # @return [DockerContainer] The updated DockerContainer instance.
    def with(options)
      options.each do |key, value|
        method_name = "with_#{key}"
        if respond_to?(method_name)
          send(method_name, value)
        else
          raise ArgumentError, "Invalid with_ method: #{method_name}"
        end
      end

      self
    end

    # Set the command for the container.
    #
    # @param parts [Array<String>] The command to run in the container as an array of strings.
    # @return [DockerContainer] The updated DockerContainer instance.
    def with_command(*parts)
      @command = parts.first.is_a?(Array) ? parts.first : parts

      self
    end

    # Set the name of the container.
    #
    # @param name [String] The name of the container.
    # @return [DockerContainer] The updated DockerContainer instance.
    def with_name(name)
      @name = name
      self
    end

    # Sets the container's environment variables.
    #
    # @param env_or_key [String, Hash, Array] The environment variable(s) to add.
    #   - When passing a Hash, the keys and values represent the variable names and values.
    #   - When passing an Array, each element should be a String in the format "KEY=VALUE".
    #   - When passing a String, it should be in the format "KEY=VALUE" or a key when a value is also provided.
    # @param value [String, nil] The value for the environment variable if env_or_key is a key (String).
    # @return [DockerContainer] The updated DockerContainer instance.
    def with_env(env_or_key, value = nil)
      add_env(env_or_key, value)
      self
    end

    # Sets the container's working directory.
    #
    # @param working_dir [String] the working directory for the container.
    # @return [DockerContainer] The updated DockerContainer instance.
    def with_working_dir(working_dir)
      @working_dir = working_dir
      self
    end

    # Adds exposed ports to the container.
    #
    # @param ports [Array<String, Integer>] The list of ports to expose.
    # @return [DockerContainer] The updated DockerContainer instance.
    def with_exposed_ports(*ports)
      add_exposed_ports(*ports)
      self
    end

    # Adds a fixed exposed port to the container.
    #
    # @param container_port [String, Integer, Hash] The container port in the format "port/protocol" or as an integer.
    #   When passing a Hash, it should contain a single key-value pair with the container port as the key and the host port as the value.
    # @param host_port [Integer, nil] The host port to bind the container port to.
    # @return [DockerContainer] The updated DockerContainer instance.
    def with_fixed_exposed_port(container_port, host_port = nil)
      add_fixed_exposed_port(container_port, host_port)
      self
    end

    # @see #with_fixed_exposed_port
    alias_method :with_port_binding, :with_fixed_exposed_port

    # Adds volumes to the container.
    #
    # @param volumes [Hash] a hash of volume key-value pairs.
    # @return [DockerContainer] The updated DockerContainer instance.
    def with_volumes(volumes = {})
      add_volumes(volumes)
      self
    end

    # Adds filesystem binds to the container.
    # @param filesystem_binds [Array, String, Hash] an array, string, or hash of filesystem binds.
    # @return [DockerContainer] The updated DockerContainer instance.
    def with_filesystem_binds(filesystem_binds)
      add_filesystem_binds(filesystem_binds)
      self
    end

    # Adds labels to the container.
    #
    # @param labels [Hash] the labels to add.
    # @return [DockerContainer] The updated DockerContainer instance.
    def with_labels(labels)
      add_labels(labels)
      self
    end

    # Adds a label to the container.
    #
    # @param label [String] the label key.
    # @param value [String] the label value.
    # @return [DockerContainer] The updated DockerContainer instance.
    def with_label(label, value)
      add_label(label, value)
      self
    end

    # Starts the container, yields the container instance to the block, and stops the container.
    #
    # @yield [DockerContainer] The container instance.
    # @return [DockerContainer] Wherever the block returns.
    def use
      start
      yield self
    ensure
      stop
    end

    # Starts the container.
    #
    # @return [DockerContainer] The DockerContainer instance.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    def start
      Docker::Image.create("fromImage" => @image)

      @_container ||= Docker::Container.create(_container_create_options)
      @_container.start

      @_id = @_container.id
      json = @_container.json

      @name = json["Name"]
      @_created_at = json["Created"]

      self
    rescue Excon::Error::Socket => e
      raise ConnectionError, e.message
    end

    alias_method :enter, :start

    # Stops the container.
    #
    # @param force [Boolean] Whether to force the container to stop.
    # @return [DockerContainer] The DockerContainer instance.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def stop(force: false)
      raise ContainerNotStartedError unless @_container
      @_container.stop(force: force)
      self
    rescue Excon::Error::Socket => e
      raise ConnectionError, e.message
    end

    # @see #stop
    alias_method :exit, :stop

    # Stops the container forcefully.
    #
    # @return [DockerContainer] The DockerContainer instance.
    # @see #stop
    def stop!
      stop(force: true)
    end

    # Kills the container with the specified signal
    #
    # @param signal [String] The signal to send to the container.
    # @return [DockerContainer] The DockerContainer instance.
    # @return [nil] If the container does not exist.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def kill(signal: "SIGKILL")
      raise ContainerNotStartedError unless @_container
      @_container.kill(signal: signal)
      self
    rescue Excon::Error::Socket => e
      raise ConnectionError, e.message
    end

    # Removes the container.
    #
    # @return [DockerContainer] The DockerContainer instance.
    # @return [nil] If the container does not exist.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    def remove
      @_container&.remove
      @_container = nil
      self
    rescue Excon::Error::Socket => e
      raise ConnectionError, e.message
    end

    # @see #remove
    alias_method :delete, :remove

    # Restarts the container.
    #
    # @return [DockerContainer] The DockerContainer instance.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def restart
      raise ContainerNotStartedError unless @_container
      @_container.restart
      self
    rescue Excon::Error::Socket => e
      raise ConnectionError, e.message
    end

    # Returns the container's status.
    # Possible values are: "created", "restarting", "running", "removing", "paused", "exited", "dead".
    #
    # @return [String] The container's status.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    def status
      raise ContainerNotStartedError unless @_container
      @_container.json["State"]["Status"]
    rescue Excon::Error::Socket => e
      raise ConnectionError, e.message
    end

    # Returns whether the container is running.
    #
    # @return [Boolean] Whether the container is running.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def dead?
      status == "dead"
    end

    # Returns whether the container is paused.
    #
    # @return [Boolean] Whether the container is paused.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def paused?
      status == "paused"
    end

    # Returns whether the container is restarting.
    #
    # @return [Boolean] Whether the container is restarting.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def restarting?
      status == "restarting"
    end

    # Returns whether the container is running.
    #
    # @return [Boolean] Whether the container is running.
    # @return [false] If the container has not been started instead of raising an ContainerNotStartedError.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    def running?
      status == "running"
    rescue ContainerNotStartedError
      false
    end

    # Returns whether the container is stopped.
    #
    # @return [Boolean] Whether the container is stopped.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def exited?
      status == "exited"
    end

    # Returns whether the container is healthy.
    #
    # @return [Boolean] Whether the container is healthy.
    # @return [false] If the container has not been started instead of raising an ContainerNotStartedError.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [HealthcheckNotSupportedError] If the container does not support healthchecks.
    def healthy?
      if supports_healthcheck?
        @_container&.json&.dig("State", "Health", "Status") == "healthy"
      else
        raise HealthcheckNotSupportedError
      end
    rescue ContainerNotStartedError
      false
    rescue Excon::Error::Socket => e
      raise ConnectionError, e.message
    end

    # Returns whether the container supports healthchecks.
    # This is determined by the presence of a healthcheck in the container's configuration.
    #
    # @return [Boolean] Whether the container supports healthchecks.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def supports_healthcheck?
      raise ContainerNotStartedError unless @_container
      @_container.json["Config"]["Healthcheck"] != nil
    end

    # Returns whether the container exists.
    #
    # @return [Boolean] Whether the container exists.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    def exists?
      return false unless @_id

      Docker::Container.get(@_id)
      true
    rescue Docker::Error::NotFoundError
      false
    rescue Excon::Error::Socket => e
      raise ConnectionError, e.message
    end

    # Returns the container's created at timestamp.
    # The timestamp is in UTC and formatted as ISO 8601. Example: "2014-10-31T23:22:05.430Z".
    #
    # @return [String] The container's created at timestamp.
    # @return [nil] If the container does not exist.
    def created_at
      @_created_at
    end

    # Returns the container's info (inspect).
    # See https://docs.docker.com/engine/api/v1.42/#tag/Container/operation/ContainerInspect
    #
    # @return [Hash] The container's info.
    # @return [nil] If the container does not exist.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def info
      raise ContainerNotStartedError unless @_container
      @_container.json
    rescue Excon::Error::Socket => e
      raise ConnectionError, e.message
    end

    # Returns the container's host.
    #
    # @return [String] The container's host.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def host
      host = docker_host
      return "localhost" if host.nil?
      raise ContainerNotStartedError unless @_container

      if inside_container? && ENV["DOCKER_HOST"].nil?
        gateway_ip = container_gateway_ip
        return bridge_ip if gateway_ip == host
        return gateway_ip
      end
      host
    rescue Excon::Error::Socket => e
      raise ConnectionError, e.message
    end

    # Returns the mapped host port for the given container port.
    #
    # @param port [Integer | String] The container port.
    # @return [Integer] The mapped host port.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def mapped_port(port)
      raise ContainerNotStartedError unless @_container
      mapped_port = container_port(port)

      if inside_container?
        gateway_ip = container_gateway_ip
        host = docker_host

        return port.to_i if gateway_ip == host
      end
      mapped_port.to_i
    rescue Excon::Error::Socket => e
      raise ConnectionError, e.message
    end

    # Returns the container's first mapped port.
    #
    # @return [Integer] The container's first mapped port.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    def first_mapped_port
      raise ContainerNotStartedError unless @_container
      container_ports.map { |port| mapped_port(port) }.first
    end

    # Returns the value for the given environment variable.
    #
    # @param key [String] The environment variable's key.
    # @return [String] The environment variable's value.
    # @return [nil] If the environment variable does not exist.
    def get_env(key)
      env_entry = env.find { |entry| entry.start_with?("#{key}=") }
      env_entry ? env_entry.split("=").last : nil
    end

    # Returns the container's logs.
    #
    # @param stdout [Boolean] Whether to return stdout.
    # @param stderr [Boolean] Whether to return stderr.
    # @return [Array<String>] The container's logs.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def logs(stdout: true, stderr: true)
      raise ContainerNotStartedError unless @_container
      stdout = @_container.logs(stdout: stdout)
      stderr = @_container.logs(stderr: stderr)
      [stdout, stderr]
    rescue Excon::Error::Socket => e
      raise ConnectionError, e.message
    end

    # Executes a command in the container.
    # See https://docs.docker.com/engine/api/v1.42/#operation/ContainerExec for all available options.
    #
    # @param cmd [Array<String>] The command to execute.
    # @param options [Hash] Additional options to pass to the Docker Exec API. (e.g `Env`)
    # @option options [Boolean] :tty Allocate a pseudo-TTY.
    # @option options [Boolean] :detach (false) Whether to attach to STDOUT/STDERR.
    # @option options [Object] :stdin Attach to stdin of the exec command.
    # @option options [Integer] :wait The number of seconds to wait for the command to finish.
    # @option options [String] :user The user to execute the command as.
    # @return [Array, Array, Integer] The STDOUT, STDERR and exit code.
    def exec(cmd, options = {}, &block)
      raise ContainerNotStartedError unless @_container
      @_container.exec(cmd, options, &block)
    rescue Excon::Error::Socket => e
      raise ConnectionError, e.message
    end

    # Waits for the container logs to match the given regex.
    #
    # @param matcher [Regexp] The regex to match.
    # @param timeout [Integer] The number of seconds to wait for the logs to match.
    # @param interval [Float] The number of seconds to wait between checks.
    # @return [Boolean] Whether the logs matched the regex.
    # @raise [ContainerNotStartedError] If the container has not been started.
    # @raise [TimeoutError] If the timeout is reached.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    def wait_for_logs(matcher, timeout: 60, interval: 0.1)
      raise ContainerNotStartedError unless @_container

      Timeout.timeout(timeout) do
        loop do
          stdout, stderr = @_container.logs(stdout: true, stderr: true)
          return true if stdout&.match?(matcher) || stderr&.match?(matcher)

          sleep interval
        end
      end
    rescue Timeout::Error
      raise TimeoutError, "Timed out waiting for logs to match #{matcher}"
    end

    # Waits for the container to be healthy.
    #
    # @param timeout [Integer] The number of seconds to wait for the health check to be healthy.
    # @param interval [Float] The number of seconds to wait between checks.
    # @return [Boolean] Whether the container is healthy.
    # @raise [ContainerNotStartedError] If the container has not been started.
    # @raise [TimeoutError] If the timeout is reached.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [HealthcheckNotSupportedError] If the container does not support healthchecks
    def wait_for_healthcheck(timeout: 60, interval: 0.1)
      raise ContainerNotStartedError unless @_container
      raise HealthcheckNotSupportedError unless supports_healthcheck?

      Timeout.timeout(timeout) do
        loop do
          return true if healthy?

          sleep interval
        end
      end
    rescue Timeout::Error
      raise TimeoutError, "Timed out waiting for health check to be healthy"
    end

    # Waits for the container to open the given port.
    #
    # @param port [Integer] The port to wait for.
    # @param timeout [Integer] The number of seconds to wait for the port to open.
    # @param interval [Float] The number of seconds to wait between checks.
    # @return [Boolean] Whether the port is open.
    # @raise [ContainerNotStartedError] If the container has not been started.
    # @raise [TimeoutError] If the timeout is reached.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [PortNotMappedError] If the port is not mapped.
    def wait_for_tcp_port(port, timeout: 60, interval: 0.1)
      raise ContainerNotStartedError unless @_container
      raise PortNotMappedError unless mapped_port(port)

      Timeout.timeout(timeout) do
        loop do
          Timeout.timeout(interval) do
            TCPSocket.new(host, mapped_port(port)).close
            return true
          end
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Timeout::Error
          sleep interval
        end
      end
    rescue Timeout::Error
      raise TimeoutError, "Timed out waiting for port #{port} to open"
    end

    # Waits for the container to respond to HTTP requests.
    #
    # @param timeout [Integer] The number of seconds to wait for the TCP connection to be established.
    # @param interval [Float] The number of seconds to wait between checks.
    # @param path [String] The path to request.
    # @param container_port [Integer] The container port to request.
    # @param https [Boolean] Whether to use TLS.
    # @param status [Integer] The expected HTTP status code.
    # @return [Boolean] Whether the container is responding to HTTP requests.
    # @raise [ContainerNotStartedError] If the container has not been started.
    # @raise [TimeoutError] If the timeout is reached.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    def wait_for_http(timeout: 60, interval: 0.1, path: "/", container_port: 80, https: false, status: 200)
      raise ContainerNotStartedError unless @_container
      raise PortNotMappedError unless mapped_port(container_port)

      Timeout.timeout(timeout) do
        loop do
          begin
            response = Excon.get("#{https ? "https" : "http"}://#{host}:#{mapped_port(container_port)}#{path}")
            return true if response.status == status
          rescue Excon::Error::Socket
            # The container may not be ready to accept connections yet
          end

          sleep interval
        end
      end
    rescue Timeout::Error
      raise TimeoutError, "Timed out waiting for HTTP status #{status} on #{path}"
    end

    # Returns whether this is running inside a container.
    #
    # @return [Boolean] Whether this is running inside a container.
    def inside_container?
      File.exist?("/.dockerenv")
    end

    private

    def normalize_ports(ports)
      return if ports.nil?
      return ports if ports.is_a?(Hash)

      ports.each_with_object({}) do |port, hash|
        hash[normalize_port(port)] = {}
      end
    end

    def normalize_port(port)
      port = port.to_s
      port = "#{port}/tcp" unless port.include?("/")
      port
    end

    def normalize_port_bindings(port_bindings)
      return if port_bindings.nil?
      return port_bindings if port_bindings.is_a?(Hash) && port_bindings.values.all? { |v| v.is_a?(Array) }

      port_bindings.each_with_object({}) do |(container_port, host_port), hash|
        hash[normalize_port(container_port)] = [{"HostPort" => host_port.to_s}]
      end
    end

    def normalize_volumes(volumes)
      return if volumes.nil?
      return volumes if volumes.is_a?(Hash)

      volumes.each_with_object({}) do |volume, hash|
        hash[volume] = {}
      end
    end

    def normalize_filesystem_binds(filesystem_binds)
      return if filesystem_binds.nil?

      if filesystem_binds.is_a?(Hash)
        filesystem_binds.map { |host, container| [host, container] }
      elsif filesystem_binds.is_a?(String)
        [filesystem_binds.split(":")]
      elsif filesystem_binds.is_a?(Array)
        filesystem_binds.map { |bind| bind.split(":") }
      else
        raise ArgumentError, "Invalid filesystem_binds format"
      end
    end

    def process_env_input(env_or_key, value = nil)
      case env_or_key
      when NilClass
        nil
      when Hash
        raise ArgumentError, "value must be nil when env_or_key is a Hash" if value
        env_or_key.map { |key, val| "#{key}=#{val}" }
      when String
        if value
          raise ArgumentError, "value must be a String when env_or_key is a String" unless value.is_a?(String)
          ["#{env_or_key}=#{value}"]
        else
          raise ArgumentError, "Invalid input format: string should include '='" unless env_or_key.include?("=")
          [env_or_key]
        end
      when Array
        raise ArgumentError, "value must be nil when env_or_key is an Array" if value
        env_or_key.each do |pair|
          unless pair.is_a?(String) && pair.include?("=")
            raise ArgumentError, "Invalid input format: array elements should be strings with '='"
          end
        end
        env_or_key
      else
        raise ArgumentError, "Invalid input format for process_env_input"
      end
    end

    def container_bridge_ip
      @_container&.json&.dig("NetworkSettings", "Networks", "bridge", "IPAddress")
    end

    def container_gateway_ip
      @_container&.json&.dig("NetworkSettings", "Networks", "bridge", "Gateway")
    end

    def container_port(port)
      @_container&.json&.dig("NetworkSettings", "Ports", normalize_port(port))&.first&.dig("HostPort")
    end

    def container_ports
      ports = @_container&.json&.dig("NetworkSettings", "Ports")&.keys || []
      ports&.map { |port| port.split("/").first }
    end

    def default_gateway_ip
      cmd = "ip route | awk '/default/ { print $3 }'"

      ip_address, _stderr, status = Open3.capture3(cmd)
      return ip_address.strip if ip_address && status.success?
    rescue
      nil
    end

    def docker_host
      return ENV["TC_HOST"] if ENV["TC_HOST"]
      url = URI.parse(Docker.url)

      case url.scheme
      when "http", "tcp"
        url.host
      when "unix", "npipe"
        if inside_container?
          ip_address = default_gateway_ip
          return ip_address if ip_address
        end
      else
        "localhost"
      end
    rescue URI::InvalidURIError
      nil
    end

    def _container_create_options
      {
        "name" => @name,
        "Image" => @image,
        "Cmd" => @command,
        "ExposedPorts" => @exposed_ports,
        "Volumes" => @volumes,
        "Env" => @env,
        "Labels" => @labels,
        "WorkingDir" => @working_dir,
        "HostConfig" => {
          "PortBindings" => @port_bindings,
          "Binds" => @filesystem_binds
        }.compact
      }.compact
    end
  end
end
