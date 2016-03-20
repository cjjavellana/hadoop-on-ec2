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

namespace :deploy do

  task :uptime do
    on roles(:named_node, :data_node) do |host|
      uptime = capture(:uptime)
      whoami = capture(:whoami)
      puts "#{host.hostname} reports: #{uptime} whoami: #{whoami}"
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
      execute "sudo mkdir -p /home/hadoop/.ssh"
      execute "sudo cp /home/ec2-user/.ssh/authorized_keys /home/hadoop/.ssh/authorized_keys"
      execute "sudo chown -R hadoop:hadoop /home/hadoop/.ssh"
      execute "sudo chmod 600 /home/hadoop/.ssh/authorized_keys"
    end
  end

  task :setup_auth, :param do |task, args|
    on roles(:named_node) do |host|      
      # Upload identity file so that we can ssh from named node to data node
      execute "mkdir -p /home/hadoop/.ec2"
      upload! "#{ENV['HOME']}/.ssh/christian_mbp15.pem", '/home/hadoop/.ec2'
      
      # Generate public key
      execute "cat /dev/zero | ssh-keygen -q -N \"\""
      args[:param].split(" ").each do |ip|
        execute "cat ~/.ssh/id_rsa.pub | ssh -o StrictHostKeyChecking=no -i /home/hadoop/.ec2/christian_mbp15.pem hadoop@#{ip} \"mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys\""
      end 
    end
  end

  task :install_hadoop do
    on roles(:named_node, :data_node), in: :parallel do |host|
      hadoop_config = ENV['hadoop_config_path']

      within '/opt' do
        execute *%w[sudo wget http://mirror.nus.edu.sg/apache/hadoop/common/hadoop-2.6.4/hadoop-2.6.4.tar.gz]
        execute *%w[sudo tar xzvf hadoop-2.6.4.tar.gz]
        execute *%w[sudo sed -i -e "s/export JAVA_HOME.*/export JAVA_HOME=\/usr\/java\/jdk1.8.0_73/g" /opt/hadoop-2.6.4/etc/hadoop/hadoop-env.sh]
        execute *%w[sudo rm -f hadoop-2.6.4.tar.gz]
      end

      # Set environment Variables
      execute "sudo sed -i '$ a ### HADOOP Variables ###' /etc/profile"
      execute "sudo sed -i '$ a export HADOOP_HOME=/opt/hadoop-2.6.4' /etc/profile"
      execute "sudo sed -i '$ a export HADOOP_INSTALL=$HADOOP_HOME' /etc/profile"
      execute "sudo sed -i '$ a export HADOOP_MAPRED_HOME=$HADOOP_HOME' /etc/profile"
      execute "sudo sed -i '$ a export HADOOP_COMMON_HOME=$HADOOP_HOME' /etc/profile"
      execute "sudo sed -i '$ a export HADOOP_HDFS_HOME=$HADOOP_HOME' /etc/profile"
      execute "sudo sed -i '$ a export YARN_HOME=$HADOOP_HOME' /etc/profile"
      execute "sudo sed -i '$ a export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native' /etc/profile"
      execute "sudo sed -i '$ a export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin' /etc/profile"
      execute "source /etc/profile"

      # Temporarily change owner to ec2-user so that we can upload
      execute "sudo chown -R ec2-user:ec2-user /opt/hadoop-2.6.4"

      upload! "#{hadoop_config}/core-site.xml", "/opt/hadoop-2.6.4/etc/hadoop/"
      upload! "#{hadoop_config}/hdfs-site.xml", "/opt/hadoop-2.6.4/etc/hadoop/"
      upload! "#{hadoop_config}/mapred-site.xml", "/opt/hadoop-2.6.4/etc/hadoop/"
      upload! "#{hadoop_config}/yarn-site.xml", "/opt/hadoop-2.6.4/etc/hadoop/"
      upload! "#{hadoop_config}/slaves", "/opt/hadoop-2.6.4/etc/hadoop/"

      # Change to hadoop user
      execute "sudo chown -R hadoop:hadoop /opt/hadoop-2.6.4"

      execute "sudo mkdir -p /data/hadoop-data/nn"
      execute "sudo mkdir -p /data/hadoop-data/snn"
      execute "sudo mkdir -p /data/hadoop-data/dn"
      execute "sudo mkdir -p /data/hadoop-data/mapred/system"
      execute "sudo mkdir -p /data/hadoop-data/mapred/local"

      execute "sudo chown -R hadoop:hadoop /data"
    end
  end

  # Updates the hostnames of the ec2 instances with the given private ip address
  # Usage:
  # cap <stage> "deploy:update_hostnames[private_ip_1=hostname_1 private_ip_2=hostname_2 private_ip_3=hostname_3 ... ]"
  # 
  # Example:
  # cap production "deploy:update_hostnames[10.0.2.51=hdp.master.node 10.0.2.61=hdp.data.node.1 10.0.2.62=hdp.data.node.2]"
  #
  task :update_hostnames, :param do |task, args|
    on roles(:named_node, :data_node), in: :parallel do |host|

      # convert the ip - node name pair to hash
      list = args[:param].split(" ").map {|x| y=x.split("="); [y[0], y[1]]}
      map = Hash[list]
      map.each_pair do |ip, hostname|
        execute "sudo sed -i '$ a #{ip} #{hostname}' /etc/hosts"
      end

      internal_ip = capture("curl http://169.254.169.254/latest/meta-data/local-ipv4")
      hostname = map[internal_ip]
      unless hostname.nil?
        puts "Updating #{internal_ip} hostname to #{hostname}"
        execute "sudo sed -i 's/^HOSTNAME=.*$/HOSTNAME=#{hostname}/g' /etc/sysconfig/network"
      else
        puts "Unable to find hostname for #{internal_ip}"
      end
    end
  end

  task :reboot
    on roles(:named_node, :data_node), in: :parallel do |host|
      execute "sudo reboot 0"
    end
  end
end