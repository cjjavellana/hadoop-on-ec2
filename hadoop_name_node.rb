#!/usr/bin/ruby

require 'rubygems'
require 'aws-sdk'
require 'byebug'

ec2                 =  Aws::EC2::Resource.new(region: 'ap-southeast-1') # choose region here
ami_name            = 'ami-0103cd62'                                    # which AMI to search for and use
key_pair_name       = 'christian_mbp15'                                 # key pair name
private_key_file    = "#{ENV['HOME']}/.ssh/christian_mbp15.pem"         # path to your private key
instance_type       = 't1.micro'                                        # machine instance type (must be approriate for chosen AMI)
ssh_username        = 'ec2'                                             # default user name for ssh'ing
security_group_name = "hadoop-namenode-sc"
dry_run = false

def get_security_group(ec2_resource, sec_group_name)
  puts "Checking if hadoop security group exists..."
  sec_group = ec2_resource.security_groups({
    filters: [
      {
        name: "group-name", 
        values: [sec_group_name]
      }
    ]
  }
  ).first

  unless sec_group
    sec_group = create_security_group(ec2_resource, sec_group_name)
    create_ingress_rules_for sec_group
  end

  sec_group
end

def create_security_group(ec2_resource)
  puts "Creating Security Group..."
  security_group = ec2_resource.create_security_group({
    dry_run: false,
    group_name: sec_group_name,
    description: sec_group_name,
    vpc_id: 'vpc-b2ab13d7'
  })
  security_group
end

def create_ingress_rules_for(security_group)
  puts "Creating Ingress Rules for Security Group #{security_group.id}..."
  security_group.authorize_ingress({
      dry_run: false,
      ip_protocol: 'tcp',
      from_port: 22,
      to_port: 22,
      cidr_ip: '0.0.0.0/0'
  })
end

def create_ec2_instance(ec2_resource, security_group)
  instances = ec2_resource.create_instances({
    dry_run: false,
    image_id: "ami-0103cd62", # required
    min_count: 1, # required
    max_count: 1, # required
    key_name: "christian_mbp15",
    instance_type: "t2.micro", # accepts t1.micro, m1.small, m1.medium, m1.large, m1.xlarge, m3.medium, m3.large, m3.xlarge, m3.2xlarge, m4.large, m4.xlarge, m4.2xlarge, m4.4xlarge, m4.10xlarge, t2.nano, t2.micro, t2.small, t2.medium, t2.large, m2.xlarge, m2.2xlarge, m2.4xlarge, cr1.8xlarge, i2.xlarge, i2.2xlarge, i2.4xlarge, i2.8xlarge, hi1.4xlarge, hs1.8xlarge, c1.medium, c1.xlarge, c3.large, c3.xlarge, c3.2xlarge, c3.4xlarge, c3.8xlarge, c4.large, c4.xlarge, c4.2xlarge, c4.4xlarge, c4.8xlarge, cc1.4xlarge, cc2.8xlarge, g2.2xlarge, g2.8xlarge, cg1.4xlarge, r3.large, r3.xlarge, r3.2xlarge, r3.4xlarge, r3.8xlarge, d2.xlarge, d2.2xlarge, d2.4xlarge, d2.8xlarge
    monitoring: {
      enabled: true, # required
    },
    disable_api_termination: true,
    instance_initiated_shutdown_behavior: "stop", # accepts stop, terminate
    network_interfaces: [{
      device_index: 0,
      subnet_id: "subnet-008fe877",
      groups: [security_group.id],
      delete_on_termination: true,
      private_ip_addresses: [{
        private_ip_address: "10.0.2.51",
        primary: true
        }],
      associate_public_ip_address: true
      }],
    ebs_optimized: false,
  })

  instances
end

def tag_instances(instances)
  instance_counter = 1
  instances.each do |instance|
    instance.create_tags({
        dry_run: false,
        tags: [{
            key: "Name",
            value: "Hadoop Named Node #{instance_counter}"
          }]
      })

    instance_counter += 1

    puts "Waiting for instance #{instance.id} to initialize..."
    instance.wait_until_running
    puts "Instance #{instance.id} initialization complete!"
  end
end

def query_public_ip(instances) 
  ids = instances.map { |m| m.instance_id }
  ec2_client = Aws::EC2::Client.new(region: 'ap-southeast-1')
  resp = ec2_client.describe_instances({
      dry_run: false,
      instance_ids: ids
    })
  ip = resp.reservations[0].instances[0].public_ip_address
  ip
end

def print_usage(ip)
  puts "EC2 Instance Created"
  puts "You may now connect to it by: ssh -i <path to your private key> ec2-user@#{ip}"
  File.open('env.txt', 'w') do |file|
    file.write ip
  end
end

security_group = get_security_group(ec2, security_group_name)
instances = create_ec2_instance(ec2, security_group)
tag_instances instances
ip_address = query_public_ip instances
print_usage ip_address

