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
  $vpc_subnets  = ['puppetdemo-is-avza', 'puppetdemo-is-avzb', 'puppetdemo-is-avzc']
  $aws_tags     = {
    'department' => $department,
    'project'    => $project,
    'created_by' => $created_by,
    'role'	 => $role,
    'env_name'   => $env_name,
  } 
 
Ec2_securitygroup {
  region => $region_name,
}

Ec2_instance {
  region            => $region_name,
  availability_zone => "${region_name}a",
}

  ec2_securitygroup { "${project}-${app_name}-${env_name}":
    ensure      => present,
    region      => $region_name,
    vpc         => $vpc_name,
    name	=> "${project}-${app_name}-${env_name}",
    description => "Security group for use by project ${project}, Application ${app_name}, Environment ${env_name}. Created by ${created_by}",
    ingress     => [
      {
        protocol => 'tcp',
        port     => '80',
        cidr     => '0.0.0.0/0',
      },
      {
        protocol => 'tcp',
        port     => '443',
        cidr     => '0.0.0.0/0',
      },
    ],
    tags => $aws_tags,
  }

ec2_launchconfiguration { "${project}-${app_name}-${env_name}-${revision}":
  ensure          => present,
  image_id        => $ami_name,
  instance_type   => $instancetype,
  key_name        => $key_name,
  region          => $region_name,
  security_groups => ["${project}-${app_name}-${env_name}", 'Allow_all_trusted_UCLA_ITServices_Subnets'],
}

elb_loadbalancer { "lb-${project}-${env_name}":
  ensure               => present,
  region               => $region_name,
  subnets	       => $vpc_subnets,
  security_groups      => "${project}-${app_name}-${env_name}",
  listeners            => [{
    protocol           => 'tcp',
    load_balancer_port => 80,
    instance_protocol  => 'tcp',
    instance_port      => 80,
  }],
  tags                 => $aws_tags,
}

ec2_autoscalinggroup { "asg-${project}-${app_name}-${env_name}-${revision}":
  ensure               => present,
  availability_zones   => ["${region_name}a", "${region_name}b", "${region_name}c"],
  launch_configuration => "${project}-${app_name}-${env_name}-${revision}",
  max_size             => 2,
  min_size             => 1,
  region               => $region_name,
  subnets              => $vpc_subnets,
}

ec2_scalingpolicy { "${project}-${app_name}-${env_name}-scaleout":
  ensure             => present,
  auto_scaling_group => "asg-${project}-${app_name}-${env_name}-${revision}",
  scaling_adjustment => 30,
  adjustment_type    => 'PercentChangeInCapacity',
  region             => $region_name,
}

ec2_scalingpolicy { "${project}-${app_name}-${env_name}-scalein":
  ensure             => present,
  auto_scaling_group => "asg-${project}-${app_name}-${env_name}-${revision}",
  scaling_adjustment => -2,
  adjustment_type    => 'ChangeInCapacity',
  region             => $region_name,
}

cloudwatch_alarm { "${project}-${app_name}-${env_name}-AddCapacity":
  ensure              => present,
  metric              => 'CPUUtilization',
  namespace           => 'AWS/EC2',
  statistic           => 'Average',
  period              => 120,
  threshold           => 70,
  comparison_operator => 'GreaterThanOrEqualToThreshold',
  dimensions          => [{
    'AutoScalingGroupName' => "asg-${project}-${app_name}-${env_name}-${revision}",
  }],
  evaluation_periods  => 2,
  alarm_actions       => ["${project}-${app_name}-${env_name}-scaleout"],
  region              => $region_name,
}

cloudwatch_alarm { "${project}-${app_name}-${env_name}-RemoveCapacity":
  ensure              => present,
  metric              => 'CPUUtilization',
  namespace           => 'AWS/EC2',
  statistic           => 'Average',
  period              => 120,
  threshold           => 40,
  comparison_operator => 'LessThanOrEqualToThreshold',
  dimensions          => [{
    'AutoScalingGroupName' => "asg-${project}-${app_name}-${env_name}-${revision}",
  }],
  evaluation_periods  => 2,
  region              => $region_name,
  alarm_actions       => ["${project}-${app_name}-${env_name}-scalein"],
}

