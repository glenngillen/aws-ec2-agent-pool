# Terraform Cloud self-hosted agent pool on EC2

A Terraform module to create a self-hosted agent pool that runs
on Amazon EC2. It will allow you to have instances to process your 
Terraform Cloud runs, within a VPC that you control, with whatever 
memory/CPU/base image dependencies you need to successfully
execute your runs.

I've found this especially useful in situations where I've needed
use the Docker provider or any other dependency that needs
elevated privilege to execute successfully.

Notes:

* It's assumed the AMI used uses `apt` for package management.
* The init script (defined in this module) will download the TFC agent and configure it to start as a service.

## Setup

* Set the `TFE_TOKEN` environment variable. It'll need to be a highly permissive token (i.e., on the `owners` team) as it needs to be able to create a new agent pool at an organizational level.
* Set the relevant variables to configure your AWS provider.

## Usage

```hcl
module "agents" {
  source            = "glenngillen/ec2-agent-pool/aws"
  version           = "1.0.3"

  org_name          = "acme-org"
  name              = "acme-agents"
  image_id          = "ami-ADA24ADZHAFS"
}
```