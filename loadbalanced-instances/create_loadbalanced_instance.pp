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

ec2_instance { ['puppet-instance-test-1', 'puppet-instance-test-2']:
  ensure          => present,
  region          => $region_name,
  image_id        => $ami_name, # you need to select your own AMI
  key_name        => $key_name,
  security_groups => ['Allow_all_trusted_UCLA_ITServices_Subnets'],
  subnet          => $subnet_name,
  instance_type   => $instancetype,
  tags            => $aws_tags,
  block_devices   => [
    {
     device_name           => '/dev/sda1',
     volume_size           => 8,
     delete_on_termination => true,
    }
  ]
}

elb_loadbalancer { "lb-${project}-${env_name}":
  ensure               => present,
  region               => $region_name,
  subnets              => $vpc_subnets,
  instances            => ['puppet-instance-test-1', 'puppet-instance-test-2'],
  security_groups      => ['Allow_all_trusted_UCLA_ITServices_Subnets'],
  listeners            => [{
    protocol           => 'tcp',
    load_balancer_port => 80,
    instance_protocol  => 'tcp',
    instance_port      => 80,
  }],
  tags                 => $aws_tags,
}
