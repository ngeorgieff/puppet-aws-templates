# Destroy all our test resources, created in the create.pp manifest
# Note that due to lifecyles of AWS resouces deleting security groups will
# fail until the corresponding instances have been deleted. This will be
# better modelled in the future.

$department   = 'engineering'
$project      = 'awsdocumentation'
$app_name     = 'shibboleth_idp'
$env_name     = 'development'
$role         = 'webserver'
$created_by   = 'Nikolay Georgieff'
$key_name     = 'engineering-lab'
$region_name  = 'us-west-2'
$vpc_name     = 'puppetdemo-is-vpc'
$revision     = '01-11-16_3'
$ami_name     = 'ami-d440a6e7'
$instancetype = 't2.nano'
$subnet_name  = 'puppetdemo-is-avza'
$vpc_subnets  = ['puppetdemo-is-avza', 'puppetdemo-is-avzb', 'puppetdemo-is-avzc']
$aws_tags     = {
  'department' => $department,
  'project'    => $project,
  'created_by' => $created_by,
  'role'       => $role,
  'env_name'   => $env_name,
}

Ec2_securitygroup {
  region => 'us-west-2',
}

Ec2_instance {
  region => 'us-west-2',
}

Elb_loadbalancer {
  region => 'us-west-2',
}

elb_loadbalancer { "lb-${project}-${env_name}":
  ensure => absent,
} ~>
ec2_instance { ['puppet-instance-test-1', 'puppet-instance-test-2']:
  ensure => absent,
} 
