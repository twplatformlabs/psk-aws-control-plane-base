
data "aws_vpc" "vpc" {
  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

data "aws_subnets" "cluster_private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = {
    Tier = var.node_subnet_identifier
  }
}

data "aws_subnet" "cluster_private_subnets" {
  for_each = toset(data.aws_subnets.cluster_private_subnets.ids)
  id       = each.value
}

data "aws_subnets" "cluster_intra_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = {
    Tier = var.intra_subnet_identifier
  }
}

# Bootstrapping the Crossplane Provider requires a provider role and eks-pod-identity-association
# this role is created in the psk-aws-iam-profiles pipeline, and the associations are created here
data "aws_iam_role" "crossplane_provider" {
  name = "PSKCrossplaneProviderRole"
}