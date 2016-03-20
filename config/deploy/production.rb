role :named_node, %w{52.77.214.121}
role :data_node, %w{54.169.204.166 54.255.183.190}

set :pty, true
set :ssh_options, {
  user: 'ec2-user',
  forward_agent: true,
  auth_methods: ['publickey'],
  keys: ["#{ENV['HOME']}/.ssh/christian_mbp15.pem"]
}
