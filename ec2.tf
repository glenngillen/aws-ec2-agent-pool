locals {
  systemd = <<EOF
[Unit]
Description=Terraform Cloud Agent

[Service]
Type=simple
User=tfc-agent
Group=tfc-agent
TimeoutStartSec=0
KillMode=process
Restart=on-failure
RestartSec=30s
ExecStart=/home/tfc-agent/bin/start.sh
SyslogIdentifier=TFCAgent

[Install]
WantedBy=multi-user.target
EOF
  script = <<EOF
#!/bin/bash
export TFC_AGENT_TOKEN=$(aws ssm get-parameters --names "${var.name}-tfc-agent-token" --with-decryption --query 'Parameters[0].Value' --output text --region="${local.region}")
export TFC_AGENT_SINGLE=false
export TFC_AGENT_NAME=${var.name}-ec2
export TFC_AGENT_DATA_DIR=/home/tfc-agent/data
/home/tfc-agent/bin/tfc-agent
EOF
}
resource "aws_launch_template" "agent" {
  name_prefix   = "${var.name}-"
  image_id      = var.image_id
  instance_type = var.instance_type

  lifecycle {
    create_before_destroy = true
  }
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      delete_on_termination = true
      volume_size = 20
    }
  }
  key_name = "glenn"

  user_data = "${base64encode(<<EOF
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get -y clean
apt-get -y update
apt-get -y dist-upgrade
apt-get -y install ca-certificates
apt-get -y install --no-install-recommends git mercurial ssh-client
apt-get -y install --no-install-recommends curl wget jq unzip iputils-ping python3.10 python3-pip awscli

apt-get -y install --no-install-recommends gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get -y update
apt-get -y install --no-install-recommends docker-ce docker-ce-cli containerd.io docker-compose-plugin
apt-get -y install --no-install-recommends ruby-full nodejs npm zip



needrestart -r a
groupadd --system tfc-agent && useradd --system --create-home --gid tfc-agent tfc-agent

usermod -a -G docker tfc-agent

mkdir -p /home/tfc-agent/bin
mkdir -p /home/tfc-agent/data

chown tfc-agent:tfc-agent /home/tfc-agent/data
chmod u+s -R /home/tfc-agent
chmod g+s -R /home/tfc-agent
setfacl -d -m g::rwX /home/tfc-agent
setfacl -d -m o::rX /home/tfc-agent

cd /home/tfc-agent
curl -o tfc-agent.zip https://releases.hashicorp.com/tfc-agent/1.2.6/tfc-agent_1.2.6_linux_amd64.zip
cd bin
unzip ../tfc-agent.zip

echo "${local.script}}" > ./start.sh
chmod +x ./start.sh
echo "${local.systemd}" > /etc/systemd/system/tfc-agent.service
systemctl start tfc-agent.service
EOF
  )}"  

  iam_instance_profile {
    name = aws_iam_instance_profile.agent.name
  }
}

resource "aws_autoscaling_group" "this" {
  availability_zones = data.aws_availability_zones.available.names
  desired_capacity   = 0
  max_size           = var.max_agents 
  min_size           = 0

  launch_template {
    id      = aws_launch_template.agent.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_iam_instance_profile" "agent" {
  name = "${var.name}-agent-instance-profile"
  role = "${aws_iam_role.agent.name}"
}

resource "aws_iam_role" "agent" {
  name               = "${var.name}-ec2-tfc-agent-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "agent_policy" {
  role   = aws_iam_role.agent.name
  name   = "AccessSSMParameterforAgentToken"
  policy = data.aws_iam_policy_document.agent_policy.json
}

data "aws_iam_policy_document" "agent_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters"]
    resources = [aws_ssm_parameter.agent_token.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken","ecr:BatchGetImage","ecr:GetDownloadUrlForLayer"]
    resources = ["*"]
  }
}


