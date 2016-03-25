class Ec2Resource

  @@ec2 =  Aws::EC2::Resource.new(region: 'ap-southeast-1')

  def self.create_security_group(group_name)
    security_group = @@ec2.create_security_group({
        dry_run: false,
        group_name: group_name,
        description: group_name,
        vpc_id: 'vpc-b2ab13d7'
      })
    security_group
  end

  # Description:
  # Retrieves the security group identified by group_name
  # 
  # Returns:
  # An instance of the security group if exists
  def self.get_security_group(group_name)
    sec_group = @@ec2.security_groups({
      filters: [
        {
          name: "group-name", 
          values: [group_name]
        }
      ]
    }
    ).first

    sec_group
  end

  # Description:
  # Creates the security group's ingress rules
  #
  # Input Parameters:
  # options: {
  #   group_name: "String", # The security group name
  #   ports: [              # The input ports to be opened
  #     { from: 8080, to: 8080 },
  #     { from: 9000, to: 10000 },
  #   ]
  # }
  #
  #
  def self.create_ingress_rules(options)
    group_name = options[:group_name]
    sec_group = self.get_security_group(group_name)
    if sec_group.nil?
      puts "Security group #{group_name} does not exist."
    else
      options[:ports].each do |port| 
        sec_group.authorize_ingress({
          dry_run: false,
          ip_protocol: 'tcp',
          from_port: port[:from],
          to_port: port[:to],
          cidr_ip: '0.0.0.0/0'
        })
      end
    end
  end
  
  # Returns {@code Instance} identified by the given tagnames
  # 
  # @tagnames - An array of tagnames. e.g. ['instance_1', 'instance_2']
  #  
  def self.get_instances_by_tagnames(tagnames)
    instances = @@ec2.instances({
        filters: [
          {
            name: 'tag-value',
            values: tagnames
          }
        ]
      })

    return instances
  end

end