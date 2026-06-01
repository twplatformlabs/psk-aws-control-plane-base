module "eks_addons" {
  source     = "aws-ia/eks-blueprints-addons/aws"
  version    = "1.23.0"
  depends_on = [module.eks]

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {

    aws-ebs-csi-driver = {
      most_recent              = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      pod_identity_association = [{
        role_arn        = module.ebs_csi_pod_identity.iam_role_arn
        service_account = "ebs-csi-controller-sa"
      }]
      configuration_values = jsonencode({
        controller = {
          nodeSelector = {
            "node.kubernetes.io/role" = "management"
          }
          tolerations = [
            {
              key      = "dedicated"
              operator = "Equal"
              value    = "management"
              effect   = "NoSchedule"
            }
          ]
        }
      })
    }

    aws-efs-csi-driver = {
      most_recent              = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      pod_identity_association = [{
        role_arn        = module.efs_csi_pod_identity.iam_role_arn
        service_account = "efs-csi-controller-sa"
      }]
      configuration_values = jsonencode({
        controller = {
          nodeSelector = {
            "node.kubernetes.io/role" = "management"
          }
          tolerations = [
            {
              key      = "dedicated"
              operator = "Equal"
              value    = "management"
              effect   = "NoSchedule"
            }
          ]
        }
      })
    }
  }
}

module "ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.8.1"

  name                      = "${var.cluster_name}-ebs-csi"
  attach_aws_ebs_csi_policy = true

  associations = {
    main = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }
}

module "efs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.8.1"

  name            = "${var.cluster_name}-efs-csi"
  attach_aws_efs_csi_policy = true

  associations = {
    main = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "efs-csi-controller-sa"
    }
  }
}
