#!/bin/bash

cap production aws:create_ec2_instance private_ip=10.0.2.51 security_group_id=sg-df17ecbb instance_type=t2.micro tag=hadoop-master-node create_public_ip=true
cap production aws:create_ec2_instance private_ip=10.0.2.61 security_group_id=sg-df17ecbb instance_type=t2.micro tag=hadoop-data-node-1 create_public_ip=true
cap production aws:create_ec2_instance private_ip=10.0.2.62 security_group_id=sg-df17ecbb instance_type=t2.micro tag=hadoop-data-node-2 create_public_ip=true
cap production deploy:yum_update

cap production deploy:install_jdk8
cap production deploy:create_hadoop_user
cap production deploy:update_host_file master_node=10.0.2.51 data_nodes=10.0.2.61,10.0.2.62


