
# This is a vpc defined type example and it provides the following:
# VPC, three subnets, an internet gateway, default routes between all subnets and access to the internet
# By default all subnets auto map to public IP on launch
$created_by           = 'Nikolay Georgieff'
$department           = 'engineering'
$project              = 'awsdemo'
$env_name	      = 'development'
$key_name             = 'engineering-lab'
$region_name          = 'us-west-2'
$vpc_mask             = '10.91.0.0'
$zone_a_mask          = '10.91.10.0'
$zone_b_mask          = '10.91.20.0'
$zone_c_mask          = '10.91.30.0'
# Do not touch anything below this line
$vpc_name             = "${project}-${department}"
$igw_name             = "${vpc_name}-igw"
$routes_name          = "${vpc_name}-routes"
$uclaits_sg_name      = "${vpc_name}-ucla-trusted-networks"
$demo_sg_name         = "${vpc_name}-demo-sg"
$crossconnect_sq_name = "${vpc_name}-crossconnect"
$aws_tags             = {
  'department'  => $department,
  'project'     => $project,
  'created_by'  => $created_by,
  'environment' => $env_name,
}

ec2_vpc { 'awsdemo-engineering-vpc':
  ensure     => present,
  region     => $region_name,
  cidr_block => "${vpc_mask}/16",
  tags       => $aws_tags,
}

ec2_vpc_subnet { "${vpc_name}-avza":
  ensure                  => present,
  region                  => $region_name,
  vpc                     => "${vpc_name}-vpc",
  cidr_block              => "${zone_a_mask}/24",
  availability_zone       => "${region_name}a",
  route_table             => $routes_name,
  map_public_ip_on_launch => true,
  require                 => [
    Ec2_vpc["${vpc_name}-vpc"],
    Ec2_vpc_routetable[$routes_name],
  ],
  tags                    => $aws_tags,
}
ec2_vpc_subnet { "${vpc_name}-avzb":
  ensure                  => present,
  region                  => $region_name,
  vpc                     => "${vpc_name}-vpc",
  cidr_block              => "${zone_b_mask}/24",
  availability_zone       => "${region_name}b",
  route_table             => $routes_name,
  map_public_ip_on_launch => true,
  require                 => [
    Ec2_vpc["${vpc_name}-vpc"],
    Ec2_vpc_routetable[$routes_name],
  ],
  tags                    => $aws_tags,
}
ec2_vpc_subnet { "${vpc_name}-avzc":
  ensure                  => present,
  region                  => $region_name,
  vpc                     => "${vpc_name}-vpc",
  cidr_block              => "${zone_c_mask}/24",
  availability_zone       => "${region_name}c",
  route_table             => $routes_name,
  map_public_ip_on_launch => true,
  require                 => [
    Ec2_vpc["${vpc_name}-vpc"],
    Ec2_vpc_routetable[$routes_name],
  ],
  tags                    => $aws_tags,
}

ec2_vpc_internet_gateway { $igw_name:
  ensure  => present,
  region  => $region_name,
  vpc     => "${vpc_name}-vpc",
  require => Ec2_vpc["${vpc_name}-vpc"],
  tags    => $aws_tags,
}

ec2_vpc_routetable { $routes_name:
  ensure => present,
  region => $region_name,
  vpc    => "${vpc_name}-vpc",
  routes => [
    {
      destination_cidr_block => "${vpc_mask}/16",
      gateway                => 'local',
    },
    {
      destination_cidr_block => '164.67.224.0/24',
      gateway                => $igw_name,
    },
  ],
  require  => [
    Ec2_vpc["${vpc_name}-vpc"],
    Ec2_vpc_internet_gateway[$igw_name],
  ],
  tags => $aws_tags,
}

ec2_securitygroup { $uclaits_sg_name:
  ensure      => present,
  region      => $region_name,
  vpc         => "${vpc_name}-vpc",
  description => 'Security group for use by the Master, and associated ports',
  ingress     => [
    {
      protocol => 'tcp',
      port     => '80',
      cidr     => '164.67.224.0/24',
    },
    {
      protocol => 'tcp',
      port     => '22',
      cidr     => '164.67.224.0/24',
    },
    {
      protocol => 'tcp',
      port     => '443',
      cidr     => '164.67.224.0/24',
    },
    {
      cidr => "${vpc_mask}/16",
      port => '-1',
      protocol => 'icmp'
    },
  ],
  tags => $aws_tags,
}

ec2_securitygroup { $demo_sg_name:
  ensure      => present,
  region      => $region_name,
  vpc         => "${vpc_name}-vpc",
  description => "Security group for use by project ${project}, Environment ${env_name}. Created by ${created_by}",
  ingress     => [
    {
      protocol => 'tcp',
      port     => '80',
      cidr     => '164.67.224.0/24',
    },
    {
      protocol => 'tcp',
      port     => '22',
      cidr     => '164.67.224.0/24',
    },
    {
      protocol => 'tcp',
      port     => '443',
      cidr     => '164.67.224.0/24',
    },
    {
      cidr => "${vpc_mask}/16",
      port => '-1',
      protocol => 'icmp'
    },
  ],
  tags => $aws_tags,
}

ec2_securitygroup { $crossconnect_sq_name:
  ensure      => present,
  region      => $region_name,
  vpc         => "${vpc_name}-vpc",
  description => "Security group for use by project ${project}, Environment ${env_name}. Created by ${created_by}",
  ingress     => [
    {
      security_group => $uclaits_sg_name,
    },
    {
      security_group => $demo_sg_name,
    },
  ],
  tags    => $aws_tags,
  require => Ec2_securitygroup[$uclaits_sg_name,$demo_sg_name],
}

