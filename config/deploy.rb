require 'bundler/capistrano'

#require "capistrano_database_yml"
#  require "capistrano_config"

set :application, "DX Scanner"
default_run_options[:pty] = true  # Must be set for the password prompt from git to work
default_environment["PATH"] = "$PATH:/usr/lib/ruby/gems/1.8/bin/"

set :scm, 'git'
set :repository, 'git://github.com/adler187/DX-Scanner.git'
set :branch, 'master'
set :deploy_via, :remote_cache
set :deploy_to, '/home/adler187/dxscan.zekesdominion.com'

# ssh_options[:user]='deployer187'
# ssh_options[:keys] = %w(/home/zeke/.ssh/id_rsa)
ssh_options[:forward_agent] = true

set :user, "deployer187"  # The server's user for deploys
#set :scm_passphrase, "eBZFPiXq"  # The deploy user's password

role :web, "dxscan.zekesdominion.com"
role :app, "dxscan.zekesdominion.com"
role :db, "dxscan.zekesdominion.com", :primary => true
# role :scanner, "zeke@10.0.0.10"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

set :use_sudo, false

after "deploy:migrations", "deploy:cleanup"

