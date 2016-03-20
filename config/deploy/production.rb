role :named_node, %w{52.77.240.155}
role :data_node, %w{54.169.42.240 52.77.217.37}

set :pty, true
set :ssh_options, {
  user: 'ec2-user',
  forward_agent: true,
  auth_methods: ['publickey'],
  keys: ["#{ENV['HOME']}/.ssh/christian_mbp15.pem"]
}
