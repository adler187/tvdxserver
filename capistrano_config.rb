#
# = Capistrano database.yml task
#
# Provides a couple of tasks for creating the database.yml
# configuration file dynamically when deploy:setup is run.
#
# Category::    Capistrano
# Package::     Database
# Author::      Simone Carletti
# Copyright::   2007-2009 The Authors
# License::     MIT License
# Link::        http://www.simonecarletti.com/
# Source::      http://gist.github.com/2769
#
#

unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance.load do

  namespace :config do

    desc <<-DESC
      Creates the config.yml in shared path
    DESC
    task :setup, :except => { :no_release => true } do

      location = fetch(:template_dir, "config/deploy") + '/config.yml.erb'
      template = File.read(location)

      config = ERB.new(template)

      run "mkdir -p #{shared_path}/config"
      put config.result(binding), "#{shared_path}/config/config.yml"
    end

    desc <<-DESC
      [internal] Updates the symlink for database.yml file to the just deployed release.
    DESC
    task :symlink, :except => { :no_release => true } do
      run "ln -nfs #{shared_path}/config/config.yml #{release_path}/config/config.yml"
    end

  end

  after "deploy:setup",           "config:setup"   unless fetch(:skip_config_setup, false)
  after "deploy:finalize_update", "config:symlink"

end 
