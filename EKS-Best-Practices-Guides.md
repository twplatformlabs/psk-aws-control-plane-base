# EKS Best Practices Guides
## Implementation Notes

For implmementation guidelines that apply to deployments in general refer to the [Application Deployment Engineering Practices](https://github.com/twplatformlabs/psk-documentation/blob/master/doc/application_deployment_engineering_practices.md).

#### Security: IAM  

**Cluster Access Recommendations**  

_Cluster Access Management_ set to `API`  

- [ ] Make EKS cluster endpoint private

This example base configuration uses public endpoints. Designing engineering quality into workload destined for public access, along with zero-trust validation strategies, benefits from comprehensive production-level static and dynamic code analysis. In many business contexts there is significant value derived from hardening and making use of pre-production environmnts accessible.  

> "By default when you provision an EKS cluster, the API cluster endpoint is set to public, i.e. it can be accessed from the Internet. Despite being accessible from the Internet, the endpoint is still considered secure because it requires all API requests to be authenticated by IAM and then authorized by Kubernetes RBAC.” - [AWS Documentation](https://docs.aws.amazon.com/eks/latest/best-practices/identity-and-access-management.html)  

- [ ] Don't use a service account token for authentication  

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

#### Security: Pod Security

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
Later application examples include polic-as-code examples using OpenPolicyAgent.  

- [x] Restrict the containers that can run as privileged
- [x] Do not run processes in containers as root;

[Guidelines](https://github.com/twplatformlabs/psk-documentation/blob/master/doc/application_deployment_engineering_practices.md)  

- [x] Never run Docker in Docker or mount the socket in the container

Platform not used for build environments.  

- [x] Restrict the use of hostPath or if hostPath is necessary restrict which prefixes can be used and configure the volume as read-only
- [x] Set requests and limits for each container to avoid resource contention and DoS attacks
```yaml
labels:
  ...
  pod-security.kubernetes.io/enforce: baseline
```

- [x] Do not allow privileged escalation;
- [x] Disable ServiceAccount token mounts;
- [x] Disable service discovery;
- [x] Configure your images with read-only root file system;

[Guidelines](https://github.com/twplatformlabs/psk-documentation/blob/master/doc/application_deployment_engineering_practices.md)

#### Security: Runtime Security

- [x] Linux Runtime and Seccomp controls

Corp runtime monitoring and threat detection. Plus [Guidelines](https://github.com/twplatformlabs/psk-documentation/blob/master/doc/application_deployment_engineering_practices.md).

#### Security: Network Security

A Service Mesh is used to create or enforce communication policies. This preserves the network as a domain of change, re-enforces zero-trust assumptions, and affords more advanced capabilities in dynamic traffic management, circuit breaking, and observability data.  

The mesh manages external ingress TLS (using LetsEncrypt certificates) and service-to-service mTLS.  

#### Security: Multi-tenancy

Broad support available for a variety of soft multi-tenancy use cases.  

#### Security: Multi Account for Multi-Tenancy Strategy

In this simulated context, two accounts are used in order to demonstrate various automation strategies.  

- RAM strategies not implemented beyond general corporate scanning
- Single VPC per cluster instance
- EKS Pod Identities prioritized, then IRSA
- Cross account limited to AWS infra layer lifecycle

#### Security: Detective Controls
- [x] Enable audit logs
- [x] Create alarms for suspicious events (corporate cloudwatch ingestion)

#### Security: Infrastructure Security

- [x] Use an OS optimized for running containers

Using [Bottlerocket](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami-bottlerocket.html).  

- [x] Keep your worker node OS updated
- [x] Treat your infrastructure as immutable and automate the replacement of your worker nodes

Karpenter node pools automatically refreshed to latest AWS Manasged AMI every 14 days (better is 4-7).  

- [x] Periodically run kube-bench to verify compliance with CIS benchmarks for Kubernetes

[FAIL] 3.2.7 Ensure that the --eventRecordQPS argument is set to 0 or a level which ensures appropriate event capture (Automated)

[FAIL] 3.2.9 Ensure that the RotateKubeletServerCertificate argument is set to true (Automated)

#### Security: Data Encryption and Secrets Management
#### Security: Regulatory Compliance
#### Security: Incidient Response and Forensics
#### Security: Image Security


upgrades: https://docs.aws.amazon.com/eks/latest/userguide/managed-node-update-behavior.html
#### Reliability: Applications
#### Reliability: Control Plane
#### Reliability: Data Plane


#### Cluster Autoscaling: Karpenter
#### Cluster Autoscaling: cluster-autoscaler
#### Cluster Autoscaling: EKS Auto Mode



#### Networking: VPC and Subnets
#### Networking: Amazon VPC CNI
#### Networking: Optimizing IP Address Utilization
#### Networking: Running IPv6 Clusters
#### Networking: Prefix Mode for Linux
#### Networking: Prefix Mode for Windows
#### Networking: Security Groups per Pod
#### Networking: Load Balancing
#### Networking: Monitoring for Network Performance Issues
#### Networking: Running kube-proxy in IPVS Mode




#### Scalability: Control Plane
#### Scalability: Data Plane
#### Scalability: Cluster Services
#### Scalability: Workloads
#### Scalability: The Tehory behind Scaling
#### Scalability: Control Plane Monitoring
#### Scalability: Node Effeciency and Scaling
#### Scalability: Kubernetes SLOs
#### Scalability: Known Limits and Service Quotas


#### Cluster Upgrades:


#### Cost Optimization: Framework
#### Cost Optimization: Awareness
#### Cost Optimization: Compute
#### Cost Optimization: Network
#### Cost Optimization: Storage
#### Cost Optimization: Observability


#### Windows Containers; N/A
#### Hybrid Deployments: and Network Disconnections


#### Running AI/ML Workloads: Compute
#### Running AI/ML Workloads: Network
#### Running AI/ML Workloads: Storage
#### Running AI/ML Workloads: Observability
#### Running AI/ML Workloads: Performance
