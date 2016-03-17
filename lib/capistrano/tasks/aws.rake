
namespace :aws do

  ec2 =  Aws::EC2::Resource.new(region: 'ap-southeast-1')
  private_key_file = "#{ENV['HOME']}/.ssh/christian_mbp15.pem" 

  # Call this task as
  # cap <stage> aws:check_security_group security_group=<group_name>
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

    puts "Security Group #{security_group} exits? #{!sec_group.nil?}"
  end
end