require "capistrano_database"
require "capistrano_config"

set :application, "DX Scanner"

# ssh_options[:user]='deployer187'
# ssh_options[:keys] = %w(/home/zeke/.ssh/id_rsa)

default_run_options[:pty] = true  # Must be set for the password prompt from git to work

# set :repository, "file:///home/adler187/svn/tvscanner/rails"
# set :local_repository,  "http://svn.zekesdominion.com/tvscanner/rails"
# set :repository,  "http://svn.zekesdominion.com/tvscanner/rails"
set :repository, "git@github.com:adler187/DX-Scanner.git"  # Your clone URL
set :branch, 'master'
set :deploy_via, :remote_cache

set :scm, "git"
set :user, "deployer187"  # The server's user for deploys
set :scm_passphrase, "eBZFPiXq"  # The deploy user's password

role :web, "dxscan.zekesdominion.com"
role :app, "dxscan.zekesdominion.com"
role :db, "dxscan.zekesdominion.com", :primary => true
# role :scanner, "zeke@10.0.0.10"

set :deploy_to, "/home/adler187/dxscan.zekesdominion.com"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

set :use_sudo, false

after "deploy:migrations", "deploy:cleanup"
