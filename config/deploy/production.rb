role :named_node, %w{54.169.220.221}
role :data_node, %w{52.77.243.253,52.77.240.79}

set :pty, true
set :ssh_options, {
  user: 'ec2-user',
  forward_agent: true,
  auth_methods: ['publickey'],
  keys: ["#{ENV['HOME']}/.ssh/christian_mbp15.pem"]
}
