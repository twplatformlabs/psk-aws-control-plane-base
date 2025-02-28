# EKS Best Practices Guides
## Implementation Notes

For implmementation guidelines that apply to deployments in general refer to the [Application Deployment Engineering Practices](https://github.com/twplatformlabs/psk-documentation/blob/master/doc/application_deployment_engineering_practices.md).

#### Security: IAM  

[x] _Cluster Access Management_ set to `API`
[ ] Make EKS cluster endpoint private

> Public endpoint meets zero-trust policy as per AWS documentation “endpoint is still considered secure because it requires all API requests to be authenticated by IAM and then authorized by Kubernetes RBAC”

[x] Don't use a service account token for authentication
[x] Employ least privileged access to AWS Resources
[x] Remove the cluster-admin permissions from the cluster creator principal

> bootstrapClusterCreatorAdminPermissions = false

[x] Use IAM Roles when multiple users need identical access to the cluster

> Human users access only through OIDC integration which generates short-lived access tokens and external authZ claims

[x] Employ least privileged access when creating RoleBindings and ClusterRoleBindings
[x] Create cluster using an automated process
[x] Create the cluster with a dedicated IAM role
[x] Regularly audit access to the cluster
[x] If relying on aws-auth configMap use tools to make changes; **N/A**
[x] Update the aws-node daemonset to use IRSA; [Source](eks-addons.tf)
[ ] Restrict access to the instance profile assigned to the worker node

_Fix_: Add launch_template configuration to MNG and K NodePools
```
resource "aws_launch_template" "foo" {
  name = "foo"
  ...
    metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
}
```
[x] Scope the IAM Role trust policy for IRSA Roles to the service account name, namespace, and cluster; [Source](eks-addons.tf)
[x] Use one IAM role per application; [Source](eks-addons.tf)
[x] When your application needs access to IMDS, use IMDSv2 and increase the hop limit on EC2 instances to 2; **N/A**
[x] Disable auto-mounting of service account tokens; [Guidelines](https://github.com/twplatformlabs/psk-documentation/blob/master/doc/application_deployment_engineering_practices.md)
[x] Use dedicated service accounts for each application; [Guidelines](https://github.com/twplatformlabs/psk-documentation/blob/master/doc/application_deployment_engineering_practices.md)
[x] Run the application as a non-root user; [Source](eks-addons.tf), [Guidelines](https://github.com/twplatformlabs/psk-documentation/blob/master/doc/application_deployment_engineering_practices.md)
[x] Grant least privileged access to applications; [Guidelines](https://github.com/twplatformlabs/psk-documentation/blob/master/doc/application_deployment_engineering_practices.md)
[x] Review and revoke unnecessary anonymous access to your EKS cluster
[x] Reuse AWS SDK sessions with IRSA; **N/A**

#### Security: Pod Security
#### Security: Multi-tenancy
#### Security: Detective Controls
#### Security: Network Security
#### Security: Data Encryption and Secrets Management
#### Security: Runtime Security
#### Security: Infrastructure Security
#### Security: Regulatory Compliance
#### Security: Incidient Response and Forensics
#### Security: Image Security
#### Security: Multi Account Strategy
#### Security:
#### Security:
#### Cluster Autoscaling: Karpenter
#### Cluster Autoscaling: clsuter-autoscaler; N/A
#### Reliability: Applications
#### Reliability: Control Plane
#### Reliability: Data Plane
#### Windows Containers; N/A
#### Networking: VPC and Subnets
#### Networking: Amazon VPC CNI
#### Networking: Optimizing IP Address Utilization
#### Networking: Running IPv6 Clusters; N/A
#### Networking: Prefix Mode for Linux
#### Networking: Prefix Mode for Windows; N/A
#### Networking: Security Groups per Pod
#### Networking: Load Balancing
#### Networking: Monitoring for Network Performance Issues
#### Scalability: Control Plane
#### Scalability: Data Plane
#### Scalability: Cluster Services
#### Scalability: Workloads
#### Scalability: Control Plane Monitoring
#### Scalability: Node Effeciency and Scaling
#### Scalability: Kubernetes SLOs
#### Scalability: Known Limits and Service Quotas
#### Cluster Upgrades:
#### Cost Optimization: Cloud Financial Management Framework
#### Cost Optimization: Compute
#### Cost Optimization: Network
#### Cost Optimization: Storage
#### Cost Optimization: Observability
