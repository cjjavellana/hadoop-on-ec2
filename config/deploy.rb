# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'my_app_name'
set :repo_url, 'git@example.com:me/my_repo.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :pty, true
set :ssh_options, {
  user: 'ec2-user',
  forward_agent: true,
  auth_methods: ['publickey'],
  keys: ["#{ENV['HOME']}/.ssh/christian_mbp15.pem"]
}

namespace :deploy do

  task :uptime do
    on roles(:named_node), in: :parallel do |host|
      uptime = capture(:uptime)
      puts "#{host.hostname} reports: #{uptime}"
    end
  end

  task :yum_update do
    on roles(:named_node), in: :parallel do |host|
      execute "sudo yum -y update"
    end
  end

  task :install_jdk8 do
    on roles(:named_node), in: :parallel do |host|
      execute "sudo yum remove -y java-1.7.0-openjdk-1.7.0.95-2.6.4.0.65.amzn1.x86_64"
      execute "wget --no-check-certificate --no-cookies --header \"Cookie: oraclelicense=accept-securebackup-cookie\" http://download.oracle.com/otn-pub/java/jdk/8u73-b02/jdk-8u73-linux-x64.rpm"
      execute "sudo rpm -ivh jdk-8u73-linux-x64.rpm"
      execute "sed -i \"sed '$ a export JAVA_HOME=/usr/java/jdk1.8.0_73' ~/.bashrc\""
    end
  end
end
