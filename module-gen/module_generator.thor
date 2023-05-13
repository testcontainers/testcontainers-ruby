require "thor"

class ModuleGenerator < Thor::Group
  include Thor::Actions

  # Module name
  argument :name

  def self.source_root
    __dir__
  end

  # Create our gem's root folder
  def make_module_folder
    self.destination_root = File.join(File.dirname(__dir__))
    empty_directory(name)
  end

  # Create our gem's root files
  def create_root_files
    template("templates/CHANGELOG.md.tt", "#{name}/CHANGELOG.md")
    template("templates/Gemfile.tt", "#{name}/Gemfile")
    template("templates/LICENSE.txt.tt", "#{name}/LICENSE.txt")
    template("templates/Rakefile.tt", "#{name}/Rakefile")
    template("templates/README.md.tt", "#{name}/README.md")
    template("templates/module.gemspec.tt", "#{name}/testcontainers-#{name}.gemspec")
  end

  # Create our gem's module files
  def create_module_files
    empty_directory("#{name}/lib/testcontainers/#{name}")
    template("templates/lib/module.rb.tt", "#{name}/lib/testcontainers/#{name}.rb")
    template("templates/lib/module/version.rb.tt", "#{name}/lib/testcontainers/#{name}/version.rb")
  end

  # Create our gem's test files
  def create_test_files
    empty_directory("#{name}/test")
    template("templates/test/test_helper.rb.tt", "#{name}/test/test_helper.rb")
    template("templates/test/module_test.rb.tt", "#{name}/test/#{name}_container_test.rb")
  end
end
