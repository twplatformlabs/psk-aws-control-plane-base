## Upgrade Notes

Minor and non-breaking changes may not warrant release notes.

### Kubernetes v1.35 to v1.36

1. gitRepo Volume Removal: The gitRepo volume type is permanently disabled in Kubernetes 1.36 and cannot be re-enabled. The Kubernetes API still accepts Pods with gitRepo volumes, but the kubelet will refuse to run them and return an error. For more info see https://github.com/kubernetes/enhancements/issues/5040.



2. SELinux Volume Labeling Changes (GA): Faster SELinux volume labeling now defaults to all volumes in Kubernetes 1.36, using mount -o context instead of recursive file relabeling. Sharing a volume between privileged and unprivileged Pods on the same node may cause issues. Future Kubernetes releases may introduce additional breaking changes related to this feature.



3. Strict IP/CIDR Validation Enabled by Default: The StrictIPCIDRValidation feature gate is now enabled by default for built-in API kinds. API fields no longer accept IP or CIDR values with extraneous leading zeros (e.g., 010.000.000.005 instead of 10.0.0.5) or CIDR values with ambiguous semantics (e.g., 192.168.0.5/24 instead of 192.168.0.0/24). Existing stored objects are preserved via validation ratcheting, but new creates and updates will be rejected. This does not apply to custom resource kinds. FOr more in fo see https://github.com/kubernetes/enhancements/issues/4858.

Not in use within PSK lab.

4. Deprecation Notice — Service externalIPs: The externalIPs field in Service .spec is deprecated in Kubernetes 1.36. You will see deprecation warnings when creating or updating Services that use this field. Full removal is planned for Kubernetes 1.43. For more info see https://github.com/kubernetes/enhancements/issues/5707.

Not in use within PSK lab.

### hashicorp.helm provider < 3.0.0

The `aws-ia/eks-blueprints-addons/aws` module still has a dependency for helm provider < v3.0.0  

### Kubernetes v1.34 to v1.35

1. Cgroup v1 Support Removed: Kubernetes 1.35 deprecates cgroup v1 support, meaning the kubelet will refuse to start by default on nodes using cgroup v1.

Using Bottlerocket for management node group and Karpenter node pools.

2. Containerd 1.x End of Support.

See no.1

3. In March 2026, the upstream Kubernetes project will retire Ingress NGINX.



### Kubernetes v1.33 to v1.34

No breaking changes described in EKS notes.

1. Containerd updated to 2.1 in Version 1.34 for launch.

Using Bottlerocket for management node group and Karpenter node pools.


2. AWS is not releasing an EKS-optimized Amazon Linux 2 AMI for Kubernetes 1.34.

See No.1

3. AppArmor is deprecated in Kubernetes 1.34.

Not in use within PSK lab.

4. VolumeAttributesClass (VAC) graduates to GA in Kubernetes 1.34, migrating from the beta API (storage.k8s.io/v1beta1) to the stable API (storage.k8s.io/v1).

RWO and RWM storage classes already using storage.k8s.io/v1

5. External JWT Signer for Service Account Tokens is promoted to Beta. 

Not in use within PSK lab.

6. Deprecation Notice - cgroup driver configuration: Manual cgroup driver

Using Bottlerocket for management node group and Karpenter node pools.

[Official release annoucements](https://kubernetes.io/blog/2025/08/27/kubernetes-v1-34-release/)

### eks-pod-identity adoption, Crossplane bootstrap identity associations

1. Moved eks-pod-identity-agent, kube-proxy, vpc-cni, coredns resource definitions from blueprint to eks provisioning module.  

2. Changed all addons to use eks-pod-identity-associations instead or Irsa roles.  

3. Created the crossplane role with admin permissions and the pod-identity associations with the specific initial CRossplane AWS provider agents needed to bootstrap crossplane to be able to manage everything else directly.  
