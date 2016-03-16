# A 2-node Hadoop Cluster
Creates a 1-named node, 2-data node hadoop cluster on EC2 using a combination of capistrano recipes and vanilla ruby (with aws-ruby-sdk) scripts.

## Usage
1. To create the named node  
```
$ ruby hadoop_named_node.rb
``` 

1.1 After executing the ``` hadoop_named_node.rb``` script. Take node of the IP address and configure config/deploy/production.rb or config/deploy/staging.rb
1.2 Update ```deploy.rb``` with your EC2 identify file

2. To configure hadoop named node
```
cap production deploy:yum_update
cap production deploy:install_jdk8
```

3. 
