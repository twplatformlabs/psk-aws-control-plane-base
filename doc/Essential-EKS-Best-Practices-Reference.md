## Security

### Security: Identity and Access Management  

_Cluster Access Manager_ set to `API`  

- [x] Combine IAM Identity Center with CAM API

This combination is implemented for the platform _service account_ identity automation.  
 
General administrator and developer (Customer) access is implemented through the oidc-provider integration.  

- [ ] Make EKS cluster endpoint private

This example base configuration uses a public endpoint. Designing engineering quality into workloads destined for public access, along with zero-trust validation strategies, benefits from comprehensive production-level static and dynamic code analysis. In many business contexts there is significant value derived from hardening and making use of pre-production as well as production environmnts.  

> "By default when you provision an EKS cluster, the API cluster endpoint is set to public, i.e. it can be accessed from the Internet. Despite being accessible from the Internet, the endpoint is still considered secure because it requires all API requests to be authenticated by IAM and then authorized by Kubernetes RBAC.” - [AWS Documentation](https://docs.aws.amazon.com/eks/latest/best-practices/identity-and-access-management.html)  

- [x] Don't use a service account token for authentication  

Control plane lifecycle automation makes use of AWS IAM machine account credentials assuming the cluster creator principal role, with actual AWS/EKS API interaction then through time-limited access tokens. These are not Kubernetes service accounts tokens. The IAM machine account credentials are automatically rotated weekly, using a standard, two-key pattern for automation resiliency.  

- [x] Employ least privileged access to AWS Resources

Human access is managed through the example oauth2/oidc integration through Auth0 according to platform product role-based access.  

- [ ] Remove the cluster-admin permissions from the cluster creator principal

Control plane lifecycle automation makes use of the cluster creator principal role in a secure, resilient machine identity automation workflow.  

- [x] Use IAM Roles when multiple users need identical access to the cluster
- [x] Employ least privileged access when creating RoleBindings and ClusterRoleBindings

Human users access only through oauth2/oidc integration which generates short-lived access tokens and has external authorization claims management.  

- [x] Create cluster using an automated process

The entire EKS lifecycle is managed through the control-plane-base pipeline.  

- [x] Create the cluster with a dedicated IAM role

EKS cluster lifecycle is assigned a dedicated IAM role, assumable only by a lifecycle machine identity, also automated and with weekly credential rotation and configuration testing.  

- [x] Regularly audit access to the cluster
- [x] If relying on aws-auth configMap use tools to make changes; **N/A**

- [x] Update the aws-node daemonset to use IRSA; [Source](eks-addons.tf)

All managed deployments to the cluster use EKS pod identity or IRSA.  

- [x] Restrict access to the instance profile assigned to the worker node

Kubernetes variant 1.33 EKS-Optimized AMI for Bottlerocket and AL2023 configured with IMDSv2 with the default hop count for MNG is set to 1.  

- [x] Scope the IAM Role trust policy for IRSA Roles to the service account name, namespace, and cluster

[Source](eks-addons.tf)

- [x] Use one IAM role per application

[Source](eks-addons.tf)

- [x] When your application needs access to IMDS, use IMDSv2 and increase the hop limit on EC2 instances to 2 **N/A**

[x] Disable auto-mounting of service account tokens;
[x] Use dedicated service accounts for each application;
[x] Run the application as a non-root user;
[x] Grant least privileged access to applications;

[Guidelines](https://github.com/twplatformlabs/psk-documentation/blob/master/doc/application_deployment_engineering_practices.md)  
[Source](eks-addons.tf)  

[x] Review and revoke unnecessary anonymous access to your EKS cluster
[x] Reuse AWS SDK sessions with IRSA; **N/A**

### Security: Pod Security

- [x] Use multiple Pod Security Admission (PSA) modes for a better user experience

Pod Security Standards (PSS)  

Platform "user" environment have Baseline PSS enforced and with audit and warning notifications at Restricted level.  
```yaml
labels:
  ...
  pod-security.kubernetes.io/warn: restricted
  pod-security.kubernetes.io/audit: restricted
  pod-security.kubernetes.io/enforce: baseline
```
Later application examples include policy-as-code examples using OpenPolicyAgent.  

General platform application development and deployment [guidelines](https://github.com/twplatformlabs/psk-documentation/blob/master/doc/application_deployment_engineering_practices.md).  

- [x] Restrict the containers that can run as privileged
- [x] Do not run processes in containers as root;
- [x] Never run Docker in Docker or mount the socket in the container

Platform not used for build environments.  

- [x] Restrict the use of hostPath or if hostPath is necessary restrict which prefixes can be used and configure the volume as read-only
- [x] Set requests and limits for each container to avoid resource contention and DoS attacks

See simple teams management and teams-api for automated namespace lifecycle management.  

- [x] Do not allow privileged escalation;
- [x] Disable ServiceAccount token mounts;
- [x] Disable service discovery;
- [x] Configure your images with read-only root file system;

### Security: Tenant Isolation

- [x] Soft Multi-tenancy

### Security: Detective Controls

- [x] Enable Audit Logs [Source](main.tf), [tfvars](environments/prod-i01-aws-us-east-2.auto.tfvars.json.tpl)
- [ ] Create alarms for suspecious events. Review on-cluster [observability]().
- [x] Audit CloudTrail logs
- [x] Analyze logs with Log Insights

### Security: Network Security

- [x] **Network Policy**

Service mesh rules used to define netorking policies.  

- [ ] Monitoring network policy enforcement. Review on-cluster [observability]().
- [x] Security groups.

Platform VPCs do not associate VPC security groups with pods, depending on mesh traffic management for policy enforcement.  

- [x] Service Mesh Policy Enforcement
- [x] Ingress Controllers and Load Balancers.

Managed through the service mesh and the Gateway API

- [x] Use encryption with AWS Elastic load balancers

TLS, and mesh managed mTLS.  

- [x] Certificates managed through cert-manager and LetsEncrypt

### Security: Data Encryption and Secrets Management

- [x] Encryption at rest

Node encryption applied  [Source](main.tf)
Storage classes provide encryption at rest.  

- [x] Secrets management

ETCD encryption  [Source](main.tf)

- [x] Rotate your secrets periodically

For platform SA example [see](https://github.com/twplatformlabs/psk-aws-iam-profiles).

- [x] Use separate namespaces as a way to isolate secrets from different applications
- [x] Use an external secrets provider

Platform uses 1password.

### Security: Runtime Security

[Guidelines](https://github.com/twplatformlabs/psk-documentation/blob/master/doc/application_deployment_engineering_practices.md) 

- [x] Seccomp
- [x] Trivy Operator

### Security: Infrastructure Security

- [x] Use an OS optimized for running containers

Using [Bottlerocket](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami-bottlerocket.html).  

- [x] Keep your worker node OS updated
- [x] Treat your infrastructure as immutable and automate the replacement of your worker nodes

Karpenter node pools automatically refreshed to latest AWS Manasged AMI every 14 days (better is 4-7). [Source](tpl/default-amd-pool-deployment.yaml)  

- [x] Periodically run kube-bench to verify compliance with CIS benchmarks for Kubernetes. [Source](scripts/kube-bench-test.sh)

No FAIL results.

- [x] Minimize access to worker nodes
- [x] Minimal IAM policy for SSM based SSH Access

Using EKS optimized nodes with no SSH access.  

- [x] Deploy workers onto private subnets

See subnet_ids in [Source](main.tf)

### Security: Regulatory Compliance

- [x] https://docs.aws.amazon.com/eks/latest/best-practices/compliance.html

### Security: Image Security

Using EKS Optimized Bottlerocket AMIs

## Cluster Autoscaling: Karpenter

Using Karpenter for cluster autoscaling.

### Reliability

see guideliness and prior references.

- [x] Spread worker nodes and workloads across multiple AZs.
