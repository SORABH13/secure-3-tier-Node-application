project_name = "toptal"
environment  = "prod"
# OIDC-related variables removed; using static AWS credentials instead
aws_region               = "us-east-1"
availability_zones       = ["us-east-1a", "us-east-1b"]
vpc_cidr                 = "10.0.0.0/16"
public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
private_app_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
private_db_subnet_cidrs  = ["10.0.21.0/24", "10.0.22.0/24"]
alb_ingress_cidrs        = ["0.0.0.0/0"]
alb_ingress_ipv6_cidrs   = ["::/0"]

db_username             = "toptaladmin"
db_password             = "5b8c4acfc69403bf46c79fdf870dee4151d49a35"
db_name                 = "toptal"
existing_db_secret_name = "toptal-prod-db-credentials"

db_instance_class       = "db.t4g.micro"
allocated_storage       = 20
engine_version          = "15.18"
backup_retention_period = 7
deletion_protection     = true


certificate_arn    = ""
cloudfront_aliases = []
