## Upgrade Notes

### Kubernetes v1.34 to v1.35

1. Cgroup v1 Support Removed: Kubernetes 1.35 deprecates cgroup v1 support, meaning the kubelet will refuse to start by default on nodes using cgroup v1.

Using Bottlerocket for management node group and Karpenter node pools.

2. Containerd 1.x End of Support.

See no.1

3. In March 2026, the upstream Kubernetes project will retire Ingress NGINX.

Not in use within PSK lab.

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

[OFficial release annoucements](https://kubernetes.io/blog/2025/08/27/kubernetes-v1-34-release/)