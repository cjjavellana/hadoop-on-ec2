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
    on roles(:named_node, :data_node), in: :parallel do |host|
      uptime = capture(:uptime)
      puts "#{host.hostname} reports: #{uptime}"
    end
  end

  task :yum_update do
    on roles(:named_node, :data_node), in: :parallel do |host|
      execute "sudo yum -y update"
    end
  end

  task :install_jdk8 do
    on roles(:named_node, :data_node) do |host|
      execute "sudo yum remove -y java-1.7.0-openjdk-1.7.0.95-2.6.4.0.65.amzn1.x86_64"
      execute "wget --no-check-certificate --no-cookies --header \"Cookie: oraclelicense=accept-securebackup-cookie\" http://download.oracle.com/otn-pub/java/jdk/8u73-b02/jdk-8u73-linux-x64.rpm"
      execute "sudo rpm -ivh jdk-8u73-linux-x64.rpm"
      execute "sed -i '$ a export JAVA_HOME=/usr/java/jdk1.8.0_73' ~/.bashrc"
    end
  end

  task :create_hadoop_user do
    on roles(:named_node, :data_node), in: :parallel do |host|
      execute "sudo useradd hadoop"
      execute "sudo echo \"hadoop:password\" | sudo chpasswd"
    end
  end

  task :setup_auth do
    on roles(:named_node) do |host|
      # Upload identity file so that we can ssh from named node to data node
      execute "mkdir -p ~/.ec2"
      upload! "#{ENV['HOME']}/.ssh/christian_mbp15.pem", '/home/ec2-user/.ec2'

      # Generate public key
      execute "cat /dev/zero | ssh-keygen -q -N \"\""
    end
  end

  task :install_hadoop do
    on roles(:named_node, :data_node), in: :parallel do |host|
      within '/opt' do
        execute *%w[sudo wget http://mirror.nus.edu.sg/apache/hadoop/common/hadoop-2.6.4/hadoop-2.6.4.tar.gz]
        execute *%w[sudo tar xzvf hadoop-2.6.4.tar.gz]
        execute *%w[sudo sed -i -e "s/export JAVA_HOME.*/export JAVA_HOME=\/usr\/java\/jdk1.8.0_73/g" /opt/hadoop-2.6.4/etc/hadoop/hadoop-env.sh]
        execute *%w[sudo chown -R hadoop:hadoop hadoop-2.6.4]
        execute *%w[sudo rm -f hadoop-2.6.4.tar.gz]
      end

      # Set environment variables
      execute "sudo sed -i '$ a ### HADOOP Variables ###' /etc/profile"
      execute "sudo sed -i '$ a export HADOOP_HOME=/opt/hadoop-2.6.4' /etc/profile"
      execute "sudo sed -i '$ a export HADOOP_INSTALL=$HADOOP_HOME' /etc/profile"
      execute "sudo sed -i '$ a export HADOOP_MAPRED_HOME=$HADOOP_HOME' /etc/profile"
      execute "sudo sed -i '$ a export HADOOP_COMMON_HOME=$HADOOP_HOME' /etc/profile"
      execute "sudo sed -i '$ a export HADOOP_HDFS_HOME=$HADOOP_HOME' /etc/profile"
      execute "sudo sed -i '$ a export YARN_HOME=$HADOOP_HOME' /etc/profile"
      execute "sudo sed -i '$ a export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native' /etc/profile"
      execute "sudo sed -i '$ a export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin' /etc/profile"
      execute "sudo source /etc/profile"
    end
  end

  task :update_host_file do
    on roles(:named_node, :data_node), in: :sequence do |host|
      master_node_ip = ENV['master_node']
      data_nodes_ip = ENV['data_nodes'].split(",")

      counter = 1
      execute "sudo sed -i '$ a #{master_node_ip} hdp.master.node' /etc/hosts"
      
      data_nodes_ip.each do |ip|
        execute "sudo sed -i '$ a #{ip} hdp.data.node.#{counter}' /etc/hosts"
        counter += 1
      end

      internal_ip = capture("curl http://169.254.169.254/latest/meta-data/local-ipv4")
      case internal_ip
        when master_node_ip
          execute "sudo sed -i 's/^HOSTNAME=.*$/HOSTNAME=hdp.master.node/g' /etc/sysconfig/network"
        when data_nodes_ip[0]
          execute "sudo sed -i 's/^HOSTNAME=.*$/HOSTNAME=hdp.data.node.1/g' /etc/sysconfig/network"
        when data_nodes_ip[1]
          execute "sudo sed -i 's/^HOSTNAME=.*$/HOSTNAME=hdp.data.node.2/g' /etc/sysconfig/network"
      end
    end
  end

  ### TODO
  ### Update hostnames
end
