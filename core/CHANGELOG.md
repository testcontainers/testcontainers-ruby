## [0.1.2] - 2023-05-13

## Added

- DockerContainer#first_mapped_port method returns the first of the
  mapped ports for convenience.

- DockerContainer#get_env(key) method to gets the value of a single
  env variable in the container

- Support custom healthchecks set with the new and
  DockerContainer#add_/with_healthcheck methods. Example:

  redis_container.with_healthcheck(test: ["redis-cli ping"], interval: 30, timeout: 30, retries: 3)

## Changed

- DockerContainer#mapped_port(port) method now returns an Integer instead of a String.

## Fixed

- Links to the GitHub project on the README.md file are fixed.

- Healtchecks handling have been fixed

## [0.1.1] - 2023-05-04

### Added

- Add .yardopts file to set the project ready for RubyDoc.info.

## [0.1.0] - 2023-05-04

### Added

- Initial release of the project with the Testcontainer::DockerContainer working.
