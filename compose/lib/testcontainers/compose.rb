require_relative "compose/version"
require "testcontainers"
require "open3"
require "pry"
module Testcontainers
  # ComposeContainer class is used to manage a large number of containers in a synchronous environment
  #
  # @attr_accesor [String] filepath used by the container
  # @attr_accesor [String,List] compose_file_name used by the container
  # @attr_accesor [Boolean] pull used by the container
  # @attr_accesor [Boolean] build used by the container
  # @attr_accesor [List] services used by the container
  class ComposeContainer < ::Testcontainers::DockerContainer

    #Default image used by the container
    DOCKER_COMPOSE_IMAGE = "docker/compose:latest"

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
    def initialize( image = DOCKER_COMPOSE_IMAGE, filepath: nil, compose_file_name: ["docker-compose.yml"], pull: false, build: false, env_file: nil , services: nil, **kwargs)
      super(image, **kwargs)
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
        docker_compose_cmd += "--env-file #{@env_file}"
      end
      docker_compose_cmd
    end

    # Generete the commands for the containers add the sentences of the function of with_command
    def start
      if @pull
        pull_cmd = "#{self.with_command()} pull"
        self.call_command(pull_cmd)
      end

      up_cmd =   " #{self.with_command()} up -d"
      if @build
        up.cmd.push('--build')
      end

      if @services.nil? == false
        up_cmd.concat(@services)
      end

      self.call_command(cmd: up_cmd)
    end

    # Generate the command for stop the containers
    def stop
      down_cmd = self.with_command() + ['down', '-v']
      self.call_command(cmd: down_cmd)
    end

    # Execute the commands with multiprocess througt the library Open3
    # @param [List] the commands to be executed   
    def call_command(cmd: nil, filepath: ".")
      binding.pry
      Open3.capture2e(*cmd, chdir: filepath)
    end

  end
end
