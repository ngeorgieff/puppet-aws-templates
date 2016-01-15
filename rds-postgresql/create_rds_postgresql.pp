
ec2_securitygroup { 'rds-postgres-group':
  ensure           => present,
  region           => 'us-west-2',
  description      => 'Group for Allowing access to Postgres (Port 5432)',
  ingress          => [{
    security_group => 'rds-postgres-group',
  },{
    protocol => 'tcp',
    port     => 5432,
    cidr     => '0.0.0.0/0',
  }]
}

rds_db_securitygroup { 'rds-postgres-db_securitygroup':
  ensure      => present,
  region      => 'us-west-2',
  description => 'An RDS Security group to allow Postgres',
}

rds_instance { 'awsdocumentation-postgres':
  ensure              => present,
  allocated_storage   => '5',
  db_instance_class   => 'db.t2.micro',
  db_name             => 'postgresql',
  engine              => 'postgres',
  license_model       => 'postgresql-license',
#  db_security_groups  => 'rds-postgres-db_securitygroup',
  master_username     => 'root',
  master_user_password=> 'pullZstringz345',
  region              => 'us-west-2',
  skip_final_snapshot => 'true',
  storage_type        => 'gp2',
}
