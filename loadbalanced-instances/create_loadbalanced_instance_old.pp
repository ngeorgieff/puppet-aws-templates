Ec2_securitygroup {
  region => 'us-west-2',
}

Ec2_instance {
  region            => 'us-west-2',
  availability_zone => 'us-west-2a',
}

ec2_instance { ['puppet-instance-test-1', 'puppet-instance-test-2']:
  ensure          => present,
  region          => 'us-west-2',
  image_id        => 'ami-d440a6e7', # you need to select your own AMI
  key_name	  => 'engineering-lab',
  security_groups => ['Allow_all_trusted_UCLA_ITServices_Subnets'],
  subnet          => 'puppetdemo-is-avza',
  instance_type   => 't2.nano',
  tags            => {
     created_by   => 'Nikolay Georgieff',
           role   => 'webserver',
       app_name   => 'shibboleth_idp',
    environment   => 'development',
     department   => 'engineering',
        project   => 'aws_documentation',
  },
  block_devices   => [
    {
     device_name           => '/dev/sda1',
     volume_size           => 8,
     delete_on_termination => true,
    }
  ]
}

elb_loadbalancer { 'lb-shibbolethidp-development':
  ensure               => present,
  region               => 'us-west-2',
  subnets              => ['puppetdemo-is-avza'],
  instances            => ['puppet-instance-test-1', 'puppet-instance-test-2'],
  security_groups      => ['Allow_all_trusted_UCLA_ITServices_Subnets'],
  listeners            => [{
    protocol           => 'tcp',
    load_balancer_port => 80,
    instance_protocol  => 'tcp',
    instance_port      => 80,
  }],
  tags                 => {
          created_by   => 'Nikolay Georgieff',
                role   => 'webserver',
            app_name   => 'shibboleth_idp',
         environment   => 'development',
          department   => 'engineering',
             project   => 'aws_documentation',
  },
}
