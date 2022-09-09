data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  region 	     = data.aws_region.current.name
  availability_zones = data.aws_availability_zones.available.names
  subnets            = cidrsubnets(var.ip_cidr_vpc, [for az in data.aws_availability_zones.available.names : 8]...)
}

output "subnets" {
  value = local.subnets
}