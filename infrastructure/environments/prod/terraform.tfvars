project_name             = "node3tier"
environment              = "prod"
github_repo              = "SORABH13/secure-3-tier-Node-application"
github_branch            = "feature/project-analysis"
aws_region               = "us-east-1"
availability_zones       = ["us-east-1a", "us-east-1b"]
vpc_cidr                 = "10.0.0.0/16"
public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
private_app_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
private_db_subnet_cidrs  = ["10.0.21.0/24", "10.0.22.0/24"]
alb_ingress_cidrs        = ["0.0.0.0/0"]
alb_ingress_ipv6_cidrs   = ["::/0"]

db_username = "node3tieradmin"
db_password = "SuperS3cureP@ssw0rd!"
db_name     = "node3tier"

db_instance_class       = "db.t4g.micro"
allocated_storage       = 20
engine_version          = "15.4"
backup_retention_period = 7
deletion_protection     = true

web_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/node3tier-web:latest"
api_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/node3tier-api:latest"

certificate_arn    = ""
cloudfront_aliases = []
