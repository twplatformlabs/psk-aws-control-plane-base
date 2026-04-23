module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.17.1"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_public_access = true
  authentication_mode    = "API"

  access_entries = {
    clusterAdmin = {
      principal_arn = "arn:aws:iam::${var.aws_account_id}:role/${var.aws_assume_role}"
      policy_associations = {
        clusterAdmin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  vpc_id                   = data.aws_vpc.vpc.id
  subnet_ids               = data.aws_subnets.cluster_private_subnets.ids
  control_plane_subnet_ids = data.aws_subnets.cluster_intra_subnets.ids

  enabled_log_types = var.enable_log_types
  create_kms_key    = true

  # For longer cluster names using the prefix goes over 38 char limit
  iam_role_use_name_prefix = false

  eks_managed_node_groups = {
    # dedicated mgmt node group, other node groups managed by karpenter
    (var.management_node_group_name) = {
      force_update_version           = true
      enable_monitoring              = true
      enable_efa_support             = false
      use_latest_ami_release_version = true
      ami_type       = var.management_node_group_ami_type
      instance_types = var.management_node_group_instance_types
      capacity_type  = var.management_node_group_capacity_type
      min_size       = var.management_node_group_min_size
      max_size       = var.management_node_group_max_size
      desired_size   = var.management_node_group_desired_size
      disk_size      = var.management_node_group_disk_size
      labels = {
        "nodegroup"               = var.management_node_group_name
        "node.kubernetes.io/role" = var.management_node_group_role
        "karpenter.sh/controller" = "true"
      }
      taints = {
        dedicated = {
          key    = "dedicated"
          value  = var.management_node_group_role
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  node_security_group_additional_rules = {
    allow_data_plane_tcp = {
      description                   = "Allow TCP Protocol Port"
      protocol                      = "TCP"
      from_port                     = 1024
      to_port                       = 65535
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}

resource "aws_eks_identity_provider_config" "auth0_oidc_config" {
  cluster_name = var.cluster_name

  oidc {
    client_id                     = var.oidc_client_id
    groups_claim                  = var.oidc_groups_claim
    identity_provider_config_name = var.oidc_identity_provider_config_name
    issuer_url                    = var.oidc_issuer_url
  }

  depends_on = [module.eks]
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_arn" {
  value = module.eks.cluster_arn
}

output "cluster_url" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_platform_version" {
  value = module.eks.cluster_platform_version
}

output "cluster_version" {
  value = module.eks.cluster_version
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "cluster_ip_family" {
  value = module.eks.cluster_ip_family
}

output "cluster_eks_managed_node_groups" {
  value = module.eks.eks_managed_node_groups
}

output "cluster_kms_key_arn" {
  value = module.eks.kms_key_arn
}

output "cluster_kms_key_id" {
  value = module.eks.kms_key_id
}

output "cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "cluster_public_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.17.1"

  cluster_name = module.eks.cluster_name
  create_pod_identity_association = true

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

output "karpenter_iam_role_arn" {
  value = module.karpenter.iam_role_arn
}

output "karpenter_node_iam_role_name" {
  value = module.karpenter.node_iam_role_name
}

output "karpenter_sqs_queue_name" {
  value = module.karpenter.queue_name
}
