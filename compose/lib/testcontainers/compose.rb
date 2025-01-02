require_relative "compose/version"
require "testcontainers"
require "open3"

module Testcontainers
  # ComposeContainer class is used to manage a large number of containers in a synchronous environment
  #
  # @attr_accesor [String] filepath used by the container
  # @attr_accesor [String,List] compose_filename used by the container
  # @attr_accesor [Boolean] pull used by the container
  # @attr_accesor [Boolean] build used by the container
  # @attr_accesor [List] services used by the container
  class ComposeContainer
    # Default image used by the container

    attr_accessor :filepath, :compose_filenames, :pull, :build, :env_file, :services

    # Initializes a new instance of ComposeContainer
    #
    # @param image [String] the image to use
    # @param filepath [String] the filepath of the configuration files for the configuration of docker compose
    # @param compose_filename [String, List] the names of the files with yml extencion for custom configuration
    # @param pull [Boolean] is the option for decide if there should be a pull request to generate the image for the containers
    # @param build [Boolean] is the option for decide if there have to use a build command for the images used for the containers
    # @param env_file [String] is the name of the envieroment configuration
    # @param services [List] are the names of the services that gonna use in the images of the containers
    def initialize(command: ["docker compose"], filepath: ".", compose_filenames: ["docker-compose.yml"],
      pull: false, build: false, env_file: nil, services: nil)

      @command = command
      @filepath = filepath
      @compose_filenames = compose_filenames
      @pull = pull
      @build = build
      @services = services
      @env_file = env_file
      @_container_started = false
    end

    # Run the containers using the `docker-compose up` command
    #
    # @return [ComposeContainer] self
    def start
      return self if @_container_started

      if @pull
        pull_cmd = compose_command("pull")
        exec_command(pull_cmd)
      end

      args = ["up", "-d"]
      args << "--build" if @build
      args << @services.join(" ") if @services
      up_cmd = compose_command(args)
      _, _, status = exec_command(up_cmd)
      @_container_started = true if status.success?

      self
    end

    # Stop the containers using the `docker-compose down` command
    #
    # @return [ComposeContainer] self
    def stop
      raise ContainerNotStartedError unless @_container_started

      down_cmd = compose_command("down -v")
      _, _, status = exec_command(down_cmd)
      @_container_started = false if status.success?

      self
    end

    def running?
      @_container_started
    end

    def exited?
      !running?
    end

    # Return the logs of the containers using the `docker-compose logs` command
    #
    # @return [String] logs
    def logs
      raise ContainerNotStartedError unless @_container_started

      logs_command = compose_command("logs")
      stdout, _, _ = exec_command(logs_command)
      stdout
    end

    # Execute a command in the given service using the `docker-compose exec` command
    #
    # @param service_name [String]
    # @param command [String]
    def exec(service_name:, command:)
      raise ContainerNotStartedError unless @_container_started

      exec_cmd = compose_command(["exec", "-T", service_name, command])
      exec_command(exec_cmd)
    end

    # Return the mapped port for a given service and port using the `docker-compose port` command
    #
    # @param service [String]
    # @return port [int]
    def service_port(service: nil, port: 0)
      raise ContainerNotStartedError unless @_container_started

      _service_info(service: service, port: port)["port"]
    end

    # Return the host for a given service and port using the `docker-compose port` command
    #
    # @param service [String]
    # @return host  [String]
    def service_host(service: nil, port: 0)
      raise ContainerNotStartedError unless @_container_started

      _service_info(service: service, port: port)["host"]
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
    def wait_for_logs(matcher:, timeout: 60, interval: 0.1)
      raise ContainerNotStartedError unless @_container_started

      Timeout.timeout(timeout) do
        loop do
          return true if logs&.match?(matcher)

          sleep interval
        end
      end
    rescue Timeout::Error
      raise TimeoutError, "Timed out waiting for logs to match #{matcher}"
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
    def wait_for_tcp_port(host:, port:, timeout: 60, interval: 0.1)
      raise ContainerNotStartedError unless @_container_started

      Timeout.timeout(timeout) do
        loop do
          Timeout.timeout(interval) do
            TCPSocket.new(host, port).close
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
    # @param service [String] The name of the service.
    # @param timeout [Integer] The number of seconds to wait for the TCP connection to be established.
    # @param interval [Float] The number of seconds to wait between checks.
    # @param path [String] The path to request.
    # @param container_port [Integer] The container port to request.
    # @param https [Boolean] Whether to use TLS.
    # @param status [Integer] The expected HTTP status code.
    # @return [Boolean] Whether the container is responding to HTTP requests.
    # @raise [ContainerNotStartedError] If the container has not been started.
    # @raise [TimeoutError] If the timeout is reached.
    # @raise [PortNotMappedError] If the port is not mapped.
    def wait_for_http(url:, timeout: 60, interval: 0.1, status: 200)
      raise ContainerNotStartedError unless @_container_started

      Timeout.timeout(timeout) do
        loop do
          begin
            response = Excon.get(url)
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

    private

    def exec_command(cmd)
      stdout, stderr, status = Open3.capture3(cmd, chdir: @filepath)

      [stdout, stderr, status]
    end

    def compose_command(args)
      # Prepare the args and command
      args = args.split(" ") if args.is_a?(String)
      compose_command = @command.dup
      compose_command = compose_command.split(" ") if compose_command.is_a?(String)

      # Add the compose files
      file_args = @compose_filenames.map { |filename| "-f #{filename}" }
      compose_command += file_args

      # Add the env file
      compose_command.push("--env-file #{env_file}") if env_file

      # Add the args
      compose_command += args

      # Return the command
      compose_command.join(" ")
    end

    # Return the host and the mapped port for the given service and port
    def _service_info(service: nil, port: 0)
      port_command = compose_command(["port", service, port])
      stdout, _, _ = exec_command(port_command)
      host, port = stdout.strip.split(":")
      {"host" => host, "port" => port}
    end
  end
end
