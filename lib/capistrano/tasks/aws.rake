
namespace :aws do

  ec2 =  Aws::EC2::Resource.new(region: 'ap-southeast-1')
  private_key_file = "#{ENV['HOME']}/.ssh/christian_mbp15.pem" 

  # Description: 
  # Returns true if the given security_group exists, false if otherwise
  #
  # Usage: 
  # cap <stage> aws:check_security_group security_group=<group_name>
  #
  task :check_security_group do
    security_group = ENV['security_group']
    sec_group = ec2.security_groups({
      filters: [
        {
          name: "group-name", 
          values: [security_group]
        }
      ]
    }
    ).first

    unless sec_group.nil?
      puts "Security Group Name: #{security_group}"
      puts "Security Group Id: #{sec_group.id}"
    else
      puts "Security Group #{security_group} does not exist"  
    end
    
  end

  # Description:
  # Creates an ec2 instance based on amazon's AMI
  #
  # Usage:
  # cap <stage> aws:create_ec2_instance private_ip=10.0.2.xx security_group_id=<security_group_id> instance_type=<t1.micro, m1.small, m1.medium, ... > tag=<instance name>
  #
  # Output:
  # Public IP Address, Instance Id
  task :create_ec2_instance do
    security_group_id = ENV['security_group_id']
    instance_type = ENV['instance_type']
    private_ip = ENV['private_ip']
    tag = ENV['tag']

    instances = ec2.create_instances({
      dry_run: false,
      image_id: "ami-0103cd62", # required
      min_count: 1, # required
      max_count: 1, # required
      key_name: "christian_mbp15",
      instance_type: instance_type, 
      monitoring: {
        enabled: true, # required
      },
      disable_api_termination: true,
      instance_initiated_shutdown_behavior: "stop", # accepts stop, terminate
      network_interfaces: [{
        device_index: 0,
        subnet_id: "subnet-008fe877",
        groups: [security_group_id],
        delete_on_termination: true,
        private_ip_addresses: [{
          private_ip_address: private_ip,
          primary: true
          }],
        associate_public_ip_address: true
        }],
      ebs_optimized: false,
    })

  instances.each do |instance|
    instance.create_tags({
        dry_run: false,
        tags: [{
            key: "Name",
            value: tag
          }]
      })

    puts "Waiting for instance #{instance.id} to initialize..."
    instance.wait_until_running
    puts "Instance #{instance.id} initialization complete!"
  end

  ids = instances.map { |m| m.instance_id }
  ec2_client = Aws::EC2::Client.new(region: 'ap-southeast-1')
  resp = ec2_client.describe_instances({
      dry_run: false,
      instance_ids: ids
    })
  ip = resp.reservations[0].instances[0].public_ip_address

  puts "Instance Id: #{ids}; Public Id: #{ip}"
  end
end