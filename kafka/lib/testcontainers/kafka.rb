require_relative "kafka/version"
require "testcontainers"
require "stringio"

module Testcontainers
  # KafkaContainer runs a single-node Kafka broker using KRaft (no ZooKeeper).
  class KafkaContainer < ::Testcontainers::DockerContainer
    KAFKA_DEFAULT_IMAGE = "confluentinc/cp-kafka:7.6.1"
    KAFKA_DEFAULT_PORT = 9092
    KAFKA_DEFAULT_CONTROLLER_PORT = 9093

    attr_reader :kafka_port, :controller_port, :host_kafka_port

    def initialize(image = KAFKA_DEFAULT_IMAGE, kafka_port: KAFKA_DEFAULT_PORT, controller_port: KAFKA_DEFAULT_CONTROLLER_PORT, host_kafka_port: KAFKA_DEFAULT_PORT, **kwargs)
      @kafka_port = kafka_port
      @controller_port = controller_port
      @host_kafka_port = host_kafka_port
      super(image, **kwargs)
      configure_environment
      add_wait_for(:tcp_port, kafka_port, timeout: 180, interval: 1) unless wait_for_user_defined?
    end

    def start
      with_fixed_exposed_port(@kafka_port, @host_kafka_port)
      with_exposed_ports(@controller_port)
      with_entrypoint(%w[/bin/bash])
      with_command(["-c", "while [ ! -f #{startup_script_path} ]; do sleep 0.1; done; #{startup_script_path}"])
      super

      copy_file_to_container("/tmp" + startup_script_path, startup_script)
      exec_as_root(%w[chmod 755] + ["/tmp" + startup_script_path])
      exec_as_root(%w[mv] + ["/tmp" + startup_script_path, startup_script_path])
      self
    end

    def port
      kafka_port
    end

    def connection_url
      "#{host}:#{mapped_port(kafka_port)}"
    end

    def bootstrap_servers
      "PLAINTEXT://#{connection_url}"
    end

    private

    def configure_environment
      add_env("KAFKA_BROKER_ID", "1")
      add_env("KAFKA_NODE_ID", "1")
      add_env("KAFKA_PROCESS_ROLES", "broker,controller")
      add_env("KAFKA_CONTROLLER_LISTENER_NAMES", "CONTROLLER")
      add_env("KAFKA_LISTENERS", "PLAINTEXT://0.0.0.0:#{kafka_port},CONTROLLER://0.0.0.0:#{controller_port}")
      add_env("KAFKA_ADVERTISED_LISTENERS", "PLAINTEXT://localhost:#{host_kafka_port}")
      add_env("KAFKA_LISTENER_SECURITY_PROTOCOL_MAP", "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT")
      add_env("KAFKA_CONTROLLER_QUORUM_VOTERS", "1@127.0.0.1:#{controller_port}")
      add_env("KAFKA_INTER_BROKER_LISTENER_NAME", "PLAINTEXT")
      add_env("KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS", "0")
      add_env("KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR", "1")
      add_env("KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR", "1")
      add_env("KAFKA_TRANSACTION_STATE_LOG_MIN_ISR", "1")
      add_env("KAFKA_NUM_PARTITIONS", "1")
      add_env("KAFKA_JVM_PERFORMANCE_OPTS", "-server -XX:+UseG1GC -Xms512m -Xmx512m")
      add_env("CLUSTER_ID", "B3lQc2gyQlNKRzh5TUpTRw==")
      add_env("KAFKA_CFG_PROCESS_ROLES", "broker,controller")
      add_env("KAFKA_CFG_CONTROLLER_LISTENER_NAMES", "CONTROLLER")
      add_env("KAFKA_CFG_LISTENERS", "PLAINTEXT://0.0.0.0:#{kafka_port},CONTROLLER://0.0.0.0:#{controller_port}")
      add_env("KAFKA_CFG_ADVERTISED_LISTENERS", "PLAINTEXT://localhost:#{host_kafka_port}")
      add_env("KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP", "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT")
      add_env("KAFKA_CFG_CONTROLLER_QUORUM_VOTERS", "1@127.0.0.1:#{controller_port}")
      add_env("KAFKA_CFG_INTER_BROKER_LISTENER_NAME", "PLAINTEXT")
      add_env("KAFKA_CFG_GROUP_INITIAL_REBALANCE_DELAY_MS", "0")
      add_env("KAFKA_CFG_TRANSACTION_STATE_LOG_REPLICATION_FACTOR", "1")
      add_env("KAFKA_CFG_TRANSACTION_STATE_LOG_MIN_ISR", "1")
      add_env("KAFKA_CFG_NUM_PARTITIONS", "1")
    end

    def startup_script_path
      "/testcontainers-kafka-start.sh"
    end

    def startup_script
      script = StringIO.new
      script.puts "#!/bin/bash"
      script.puts "set -euo pipefail"
      script.puts "CLUSTER_ID=${CLUSTER_ID:-'4L6g3n4kTAW5y-5Pb0jzGw'}"
      script.puts "KAFKA_LOG_DIR=/var/lib/kafka/data"
      script.puts "CONFIG_FILE=/etc/kafka/kraft/server.properties"
      script.puts "if [ ! -f \"$KAFKA_LOG_DIR/meta.properties\" ]; then"
      script.puts "  kafka-storage format --config $CONFIG_FILE --cluster-id $CLUSTER_ID --ignore-formatted"
      script.puts "fi"
      script.puts "exec /etc/confluent/docker/run"
      script
    end

    def exec_as_root(cmd, options = {})
      exec(cmd, options.merge({"User" => "root"}))
    end
  end
end
