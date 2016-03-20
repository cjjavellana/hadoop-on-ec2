# EC2 Hadoop Cluster

Creates a Hadoop cluster on AWS EC2

## Quickstart
1. Obtain your AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY from AWS and add it into your ~/.bashrc or ~/.bash_profile or /etc/profile  
2. Obtain your AWS identity file (*.pem)  
3. Update config/deploy/production.rb and config/deploy/production_hadoop.rb to refer to the location of your pem file. Furthermore, you can take it
 a notch by externalizing the location of your identity file and referring to it as an environment variable from config/deploy/production.rb and config/deploy/production_hadoop.rb.  
4. Create and configure your AWS subnet (currently outside the scope of this automation script). Define your subnet mask and take note of the subnet id.
5. Create and configure your cluster security group (currently outside the scope of this automation script) and open the following ports:  
..* 22 (So that you can SSH)
..* 8030 - 8100
..* 50070
..* 50075
..* 50475
..* 50105
..* 50470
..* 2181 (not required by hadoop, this is a zookeeper port)
..* 50090  
6. Customize the ```create_hdp_cluster.sh``` script according to your subnet choices.  
7. Run the script and monitor your EC2 instance dashboard
```
$ ./create_hdp_cluster.sh
```

Enjoy!