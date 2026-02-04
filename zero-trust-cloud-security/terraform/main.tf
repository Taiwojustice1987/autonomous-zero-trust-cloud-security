###############################
# Terraform & Provider Setup
###############################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.region
}

###############################
# Variables
###############################
variable "region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  default     = "10.0.1.0/24"
}

###############################
# VPC (Zero Trust Base)
###############################
resource "aws_vpc" "zero_trust_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "ZeroTrust-VPC"
    Purpose = "Autonomous Zero Trust Security Research"
  }
}

###############################
# Private Subnet (No Public IPs)
###############################
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.zero_trust_vpc.id
  cidr_block              = var.private_subnet_cidr
  map_public_ip_on_launch = false

  tags = {
    Name = "ZeroTrust-Private-Subnet"
  }
}

###############################
# Private Route Table (NO Internet / NO NAT)
# Local-only routing inside the VPC
###############################
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.zero_trust_vpc.id

  tags = {
    Name = "ZeroTrust-Private-RT"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

###############################
# Security Group (Zero Trust baseline)
###############################
resource "aws_security_group" "private_sg" {
  name        = "ZeroTrust-Private-SG"

  # ✅ IMPORTANT: revert to original to avoid SG replacement/destruction
  description = "Security group for private subnet (no internet egress)"

  vpc_id      = aws_vpc.zero_trust_vpc.id

  # Allow only internal VPC traffic (tight baseline)
  ingress {
    description = "Allow internal VPC traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # ✅ Allow outbound traffic (required for DNS + S3 via VPC Endpoint)
  # Still NO NAT: your route table has no 0.0.0.0/0 route.
  egress {
    description = "Allow all outbound (DNS + AWS service access via endpoints; no NAT routes)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ZeroTrust-Private-SG"
  }
}

###############################
# VPC Flow Logs (for monitoring / AI anomaly detection)
###############################
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/zero-trust/vpc-flow-logs"
  retention_in_days = 30
}

resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "ZeroTrustVPCFlowLogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name = "ZeroTrustVPCFlowLogsPolicy"
  role = aws_iam_role.vpc_flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc_flow" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.zero_trust_vpc.id
  iam_role_arn         = aws_iam_role.vpc_flow_logs_role.arn
}
