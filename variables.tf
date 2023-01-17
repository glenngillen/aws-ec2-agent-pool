variable "desired_count" {
  description = "Desired count of tfc-agents to run."
  default     = 0
}

variable "ip_cidr_vpc" {
  description = "IP CIDR for VPC"
  default     = "172.31.0.0/16"
}

variable "ip_cidr_agent_subnet" {
  description = "IP CIDR for tfc-agent subnet"
  default     = "172.31.16.0/24"
}

variable "org_name" {
  description = "Organization to create agent pool in."
}
variable "name" {
  description = "Name for the agent pool & resources."
}

variable "image_id" {
  description = "ID of the AMI to use."
}

variable "max_agents" {
  description = "Maximum number of agents to allow."
  default = 2
}

variable "instance_type" {
  description = "Instance type to use."
  default = "t3.micro"
}

variable "user_data" {
  description = "Custom user_data to insert as part of EC2 startup process"
  default = ""
}