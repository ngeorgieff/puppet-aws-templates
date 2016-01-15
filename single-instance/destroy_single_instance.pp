# Destroy all our test resources, created in the create.pp manifest
# Note that due to lifecyles of AWS resouces deleting security groups will
# fail until the corresponding instances have been deleted. This will be
# better modelled in the future.

Ec2_securitygroup {
  region => 'us-west-2',
}

Ec2_instance {
  region => 'us-west-2',
}

Elb_loadbalancer {
  region => 'us-west-2',
}

ec2_instance { ['puppet-instance-test-1']:
  ensure => absent,
} 

