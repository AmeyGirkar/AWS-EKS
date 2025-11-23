###############################################################
#
# This file contains configuration for all data source queries
#
###############################################################

# Get the default VPC details
data "aws_vpc" "default_vpc" {
  default = true
}

# Get Public IP of your broadband account. This allows us to lock down SSH access
# into the environment from anyone other than yourself, by inserting your public
# IP to a security group ingress rule.
# Try this URL in your browser!
data "http" "cloudshell_ip" {
  url = "https://checkip.amazonaws.com/"
}

# Get the subnets to use for the cluster to bind to and the autoscaling group
# to place nodes in.
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
  filter {
    name = "availability-zone"
    values = [
      "${var.aws_region}a",
      "${var.aws_region}b",
      "${var.aws_region}c",
    ]
  }
}

# Get AMI ID for latest recommended Amazon Linux 2 image
data "aws_ssm_parameter" "node_ami" {
  name = "/aws/service/eks/optimized-ami/1.31/amazon-linux-2/recommended/image_id"
}

# List of EKS addon names to install on the cluster
locals {
  # Map of addon name -> object with optional `version` string.
  # Leave `version` empty to install the provider/chosen default (latest compatible).
  eks_addons = {
    "vpc-cni"            = { version = "v1.20.0-eksbuild.1" }
    "kube-proxy"         = { version = "v1.33.0-eksbuild.2" }
    "coredns"            = { version = "v1.12.2-eksbuild.4" }
    "aws-ebs-csi-driver" = { version = "v1.46.0-eksbuild.1" }
  }
}

