terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "ap-southeast-2"
}

variable "instance_type" {
  default = "t3.small"
}

variable "ami_id" {
  default = "ami-0f5d1713c9af4fe30"
}

variable "key_name" {
  default = "myMacbook"
}

variable "subnet_id" {
  default = "subnet-0f72be4624adad8ff"
}

variable "vpc_id" {
  default = "vpc-0cc3c139f96487cc0"
}

variable "nomad_version" {
  default = "1.9.7"
}

resource "aws_security_group" "nomad_sg" {
  name        = "tf-nomad-sg"
  description = "Secgroup for Nomad"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4647
    to_port     = 4647
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nomad_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.nomad_sg.id]
  tags = {
    Name = "tf-nomad-server"
  }

  user_data = <<-EOF
  #!/bin/bash
  apt-get update
  apt-get install -y unzip
  curl -o /tmp/nomad.zip https://releases.hashicorp.com/nomad/${var.nomad_version}/nomad_${var.nomad_version}_linux_amd64.zip
  unzip /tmp/nomad.zip -d /usr/local/bin/
  chmod +x /usr/local/bin/nomad
  mkdir -p /opt/nomad/data
  mkdir -p /etc/nomad.d

  cat <<'EOT' > /etc/nomad.d/nomad.hcl
  data_dir = "/opt/nomad/data"
  bind_addr = "0.0.0.0"
  server {
    enabled = true
    bootstrap_expect = 1
  }
  EOT

  cat <<'EOT' > /etc/systemd/system/nomad.service
  [Unit]
  Description=Nomad
  Wants=network-online.target
  After=network-online.target

  [Service]
  ExecStart=/usr/local/bin/nomad agent -config=/etc/nomad.d/nomad.hcl
  ExecReload=/bin/kill -HUP $MAINPID
  Restart=always
  RestartSec=10

  [Install]
  WantedBy=multi-user.target
  EOT

  systemctl daemon-reload
  systemctl enable nomad
  systemctl start nomad
  EOF
}

output "nomad_web_url" {
  value = "http://${aws_instance.nomad_server.public_ip}:4646"
}
