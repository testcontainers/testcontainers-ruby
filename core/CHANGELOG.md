## Unreleased

### Added

- DockerContainer#new now accepts optional keyword argument `image_create_options` which accepts a hash. Passes the options to `Docker::Image.create`. See the [Docker ImageCreate api](https://docs.docker.com/engine/api/v1.43/#tag/Image/operation/ImageCreate) for available parameters.

- DockerContainer#remove now accepts an optional options hash. See the [Docker ContainerDelete api](https://docs.docker.com/engine/api/v1.43/#tag/Container/operation/ContainerDelete) for available parameters.

## [0.1.3] - 2023-06-10

### Added

- Support for entrypoint customization and the DockerContainer#with_entrypoint method

- Methods to read/write strings from and to containers: read_file, store_file

- Methods to copy files from and to containers: copy_file_from_container, copy_file_to_container

- Support for waiting strategies on start

- DockerContainer#with_exposed_port (singular) for convenience

- GenericContainer as alias for DockerContainer

### Fixed

- DockerContainer#add_exposed_ports don't override PortBinding settings added by #add_fixed_exposed_port


## [0.1.2] - 2023-05-13

### Added

- DockerContainer#first_mapped_port method returns the first of the
  mapped ports for convenience.

- DockerContainer#get_env(key) method to gets the value of a single
  env variable in the container

- Support custom healthchecks set with the new and
  DockerContainer#add_/with_healthcheck methods. Example:

  redis_container.with_healthcheck(test: ["redis-cli ping"], interval: 30, timeout: 30, retries: 3)

### Changed

- DockerContainer#mapped_port(port) method now returns an Integer instead of a String.

### Fixed

- Links to the GitHub project on the README.md file are fixed.

- Healtchecks handling have been fixed

## [0.1.1] - 2023-05-04

### Added

- Add .yardopts file to set the project ready for RubyDoc.info.

## [0.1.0] - 2023-05-04

### Added

- Initial release of the project with the Testcontainer::DockerContainer working.
