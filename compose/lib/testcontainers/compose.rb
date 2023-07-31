require_relative "compose/version"
require "testcontainers"
require "open3"
require "pry"
require "net/http"
require "json"
require "uri"
module Testcontainers
  # ComposeContainer class is used to manage a large number of containers in a synchronous environment
  #
  # @attr_accesor [String] filepath used by the container
  # @attr_accesor [String,List] compose_file_name used by the container
  # @attr_accesor [Boolean] pull used by the container
  # @attr_accesor [Boolean] build used by the container
  # @attr_accesor [List] services used by the container
  class ComposeContainer

    #Default image used by the container

    attr_accessor :filepath, :compose_file_name, :pull, :build, :env_file, :services

    # Initializes a new instance of ComposeContainer
    #
    # @param image [String] the image to use
    # @param filepath [String] the filepath of the configuration files for the configuration of docker compose
    # @param compose_file_name [String, List] the names of the files with yml extencion for custom configuration
    # @param pull [Boolean] is the option for decide if there should be a pull request to generate the image for the containers
    # @param build [Boolean] is the option for decide if there have to use a build command for the images used for the containers
    # @param env_file [String] is the name of the envieroment configuration
    # @param services [List] are the names of the services that gonna use in the images of the containers 
    def initialize(filepath: ".", compose_file_name: ["docker-compose.yml"], pull: false, build: false, env_file: nil , services: nil, **kwargs)
      @filepath = filepath
      @compose_file_names = compose_file_name
      @pull = pull
      @build = build
      @services = services
      @env_file = env_file
    end

    # Specify the names of the all names of the configuration files
    # @return [docker_compose_cmd] 
    def with_command
      docker_compose_cmd = ['docker compose']
      @compose_file_names.each do |file|
        docker_compose_cmd += ["-f  #{file}"]
      end
      if env_file.nil? == false
        docker_compose_cmd.push("--env-file #{@env_file}")
      end
      docker_compose_cmd.join(" ")
    end

    # Generete the commands for the containers add the sentences of the function of with_command
    def start
      if @pull
        pull_cmd = "#{with_command()} pull"
        Open3.capture2(pull_cmd, chdir: @filepath)
      end

      up_cmd =  " #{with_command()} up -d"
      if @build
        up_cmd.concat(' --build')
      end

      if @services
        up_cmd.concat(@services.join(" "))
      end

      if @build
      binding.pry
      end

      Open3.capture2(up_cmd, chdir: @filepath)
    end

    # Generate the command for stop the containers
    def stop
      down_cmd = with_command().concat(' down -v')
      #call_command(cmd: down_cmd, option: 1)
      Open3.capture2(down_cmd, chdir: @filepath)
    end

    def logs
      command_logs = with_command.concat(" logs")
      Open3.capture3(command_logs, chdir: @filepath)
    end

    def run_in_container(service_name: nil, command: nil )
      command_exec = with_command.concat(" exec -T #{service_name} #{command}")
      Open3.capture2(command_exec, chdir: @filepath)
    end

    def port_process(service: nil, port: 0)
      process_information(service: service, port: port)[0]
    end

    def host_process(service: nil, port: 0)
      process_information(service: service, port: port)[1]
    end

    def process_information(service:nil , port: 0)
      command_port = with_command().concat(" port #{service} #{port}")
    # stdout2, stderr2,status2 = call_command(cmd: command_port, option: 3)
    # stdout2.split(":"), stderr2, status2
     #stdout_splitted = stdout.split(":")
     #stdout_splitted, stderr, status
      stdout, stderr, status = Open3.capture3(command_port, chdir: @filepath)
      host, port = stdout.strip.split(':')
      [host, port, stderr, status]
    end

    # Execute the commands with multiprocess througt the library Open3
    # @param [List] the commands to be executed
  ##def call_command(cmd: nil, option: 1)
  ## case option
  ## when 1
  ##   stdout, status = Open3.capture2(cmd, chdir: @filepath)
  ##   return stdout, status
  ## when 2
  ##   stdout2, stderr2 = Open3.popen3(cmd, chdir: @filepath)
  ##   return stdout2, stderr2
  ## when 3
  ##   stdout3, stderr3 = Open3.capture3(cmd, chdir: @filepath)
  ##   return stdout3,stderr3
  ## else
  ##   puts "Not command in the  code"
  ## end
  ##end

    def wait_for_request(url: nil)
      url =URI.parse(url) 
      http = Net::HTTP.new(url.host, url.port)

      request = Net::HTTP::Get.new(url)
      http.request(request)
    end
  end
end
