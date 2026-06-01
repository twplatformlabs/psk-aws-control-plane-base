# bootstrapPod-identity for the Crossplane aws family providers. See psk-platform-ext-crossplane for details
resource "aws_eks_pod_identity_association" "crossplane_provider" {
  cluster_name    = module.eks.cluster_name
  namespace       = "crossplane-system"
  service_account = "upbound-provider-family-aws"
  role_arn        = data.aws_iam_role.crossplane_provider.arn
}

resource "aws_eks_pod_identity_association" "crossplane_iam_provider" {
  cluster_name    = module.eks.cluster_name
  namespace       = "crossplane-system"
  service_account = "upbound-provider-aws-iam"
  role_arn        = data.aws_iam_role.crossplane_provider.arn
}

resource "aws_eks_pod_identity_association" "crossplane_eks_provider" {
  cluster_name    = module.eks.cluster_name
  namespace       = "crossplane-system"
  service_account = "upbound-provider-aws-eks"
  role_arn        = data.aws_iam_role.crossplane_provider.arn
}

resource "aws_eks_pod_identity_association" "crossplane_ksm_provider" {
  cluster_name    = module.eks.cluster_name
  namespace       = "crossplane-system"
  service_account = "upbound-provider-aws-kms"
  role_arn        = data.aws_iam_role.crossplane_provider.arn
}

output "crossplane_provider_role_arn" {
  value = data.aws_iam_role.crossplane_provider.arn
}