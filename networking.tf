resource "aws_vpc" "main" {
  cidr_block = var.ip_cidr_vpc
}

resource "aws_subnet" "tfc_agent" {
  for_each          = toset(local.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.subnets[index(local.availability_zones, each.value)]
  availability_zone = each.value
}

resource "aws_security_group" "tfc_agent" {
  name_prefix = "${var.name}-sg"
  description = "Security group for tfc-agent-vpc"
  vpc_id      = aws_vpc.main.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_egress" {
  security_group_id = aws_security_group.tfc_agent.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "main" {
  for_each       = aws_subnet.tfc_agent    
  subnet_id      = each.value.id
  route_table_id = aws_route_table.main.id
}
