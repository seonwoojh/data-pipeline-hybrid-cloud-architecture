## Random password를 생성한다.
resource "random_password" "db_password" {
    length = 16
    special = true
}

## DB 인스턴스의 서브넷 그룹을 생성한다.
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "RDS subnet group"
  }
}

## RDS 인스턴스를 생성한다.
resource "aws_db_instance" "DB_Slave" {
    db_name = "DB_Slave"
    # availability_zone     = "ap-northeast-2a"
    allocated_storage    = 20
    engine               = "mysql"
    engine_version       = "8.0.36"
    instance_class       = "db.t3.micro"
    username             = "admin"
    password             = random_password.db_password.result
    db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
    vpc_security_group_ids = [module.vpc.default_security_group_id]
    parameter_group_name = aws_db_parameter_group.DB_Slave_Params.name
    backup_retention_period = 30
    skip_final_snapshot  = true
    publicly_accessible = false

  tags = {
    Name = "DB_Slave_Instance"
  }
}

resource "aws_db_parameter_group" "DB_Slave_Params" {
  name   = "rds-pg"
  family = "mysql8.0"

  parameter {
    name  = "autocommit"
    value = "1"
  }

  parameter {
    name = "gtid-mode"
    value = "ON_PERMISSIVE"
  }

  parameter {
    name = "enforce_gtid_consistency"
    value = "ON"
  }
}