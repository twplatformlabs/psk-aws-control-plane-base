<div align="center">
	<p>
	<img alt="Thoughtworks Logo" src="https://raw.githubusercontent.com/twplatformlabs/static/master/psk_banner.png" width=800 />
	<h2>psk-aws-control-plane-base</h2>
	<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/github/license/twplatformlabs/psk-aws-control-plane-base"></a> <a href="https://aws.amazon.com"><img src="https://img.shields.io/badge/-deployed-blank.svg?style=social&logo=amazon"></a>
	</p>
</div>

This `control plane base` pipeline is intended to be limited to all, and only, those components of EKS that are managed by AWS. Deployments, version changes, and removal of the associated resources belong to AWS in the shared-responsibility model of IaaS vendor managed services. The pipeline owner directs only 'when' such changes occur by specifying version changes in the environment configuration or other similar practices of notifying AWS of a change to be made. In addition, cautiously consider including a customization to the core EKS configuration that is part of your overall architecture and without which the Kubernetes control plane itslef would not be capable of initial communication. An example of this might be the use of an alternative CNI or the basic Karpenter install.

## AWS Managed EKS Control Plane

```mermaid
---
title: EKS Managed architecture
---
flowchart LR

    VPC --- PODID
    EBSCSI --> RWO --- PODID
    EFSCSI --> RWM --- PODID
    EBSNODE --- PODID
    EFSNODE --- PODID
    DNS --- PODID
    EVNT --> SQS --> KRPT
    LOGS --- LOGS1

    subgraph Control Plane Base
        subgraph Management Node Pool
            DNS[CoreDNS]
            EBSCSI[ebs-csi-controller]
            EFSCSI[efs-csi-controller]
            LOGS[Cloudwatch Logs]
            KRPT[Karpenter]
        end
        subgraph daemons
            KP[kube-proxy]
            VPC[vpc-cni]
			EBSNODE[ebs-csi-node]
			EFSNODE[efs-csi-node]
        end
    end

    PODID@{ shape: brace-l, label: "eks-pod-identities" }
    RWO[(RW-One storageclass)]
    RWM[(RW-Many storageclass w/general mnt)]
    LOGS1@{ shape: brace-l, label: "api, audit, authenticator, controllerManager, scheduler" }
    SQS@{ shape: rounded, label: "SQS"}
    EVNT@{ shape: trap-b, label: "Event Bridge"}

```

```mermaid
---
title: Terraform Resources
---
flowchart LR
    subgraph crossplane bootstrap
        subgraph eks-pod-identity-associations
            upbound-provider-family-aws
            upbound-provider-aws-iam
            upbound-provider-aws-eks
            upbound-provider-aws-kms
        end
    end
    subgraph helm release
        karpenter-crds
        karpenter
    end
    subgraph terraform-aws-modules/eks/aws//modules/karpenter
        event-brige
        sqs-queue
    end
    subgraph cloudposse/efs/aws
        DEF[Default EFS mount - claims automatically on namespaced folderpaths]
    end
    subgraph aws-ia/eks-blueprints-addons
        aws-ebs-csi-driver
        aws-efs-csi-driver
    end
    subgraph aws_eks_identity_provider_config
        TEN[pskctl Auth0 tenant]
    end
    subgraph terraform-aws-modules/eks
        subgraph eks managed nodegroup
            MgmtPool@{ shape: procs, label: "management-arm-rkt-mng"}
        end
        subgraph addons
        ADD["eks-pod-identity-agent
            kube-proxy
            coredns
            vpc-cni
            "]
        end
        subgraph cluster definition
        end
    end
```
1. ARM Arch Managed Node Group for dedicated management pool with specific toleration requirement.

```yaml
nodeSelector:
	"node.kubernetes.io/role": "management"
tolerations:
	key: "dedicated"
	operator: "Equal"
	value: "management"
	effect: "NoSchedule"
```
2. AWS managed EKS Addons

* kube-proxy
* eks-pod-identity-agent
* vpc-cni
* coredns
* aws-ebs-csi-driver
* aws-efs-csi-driver
	* common efs target created, filesystem-id stored in 1password, make discoverable via platforms/clusters API
* karpenter
	* managed disruption events via sqs and eventbridge
	* default arm and amd NodePools resources defined
		* target desired architecture with `kubernetes.io/arch` = "arm64" | "amd64"

3. psk-system and karpenter namespaces created
4. admin ClusterRolebinding created for twplatformlabs/platform team claim
5. aws_eks_pod_identity_association to PSKCrossplaneProviderRole created for aws provider bootstrap

* `upbound-provider-family-aws`
* `upbound-provider-aws-iam`
* `upbound-provider-aws-ksm`
* `upbound-provider-aws-eks`

6. cluster-info config map set to support ArgoCD Core, role-based cluster config management

## Authentication modes
```mermaid
---
title: Kubernetes API Access Controls
---
flowchart LR

    RT --- SA1 --> | IAM | FW --> NLB --> | AssumeRole | ROLE
    USER2 --> | oauth2 device-auth-flow | AUTH0 --> FW --> NLB --> | oidc | ID --- CLAIM
    SA2 --> | oauth2 custom token exchange | AUTH0 --> FW --> NLB --> | oidc | ID

        
    subgraph authentication mode API
        subgraph access_entries
            ROLE[PSKRoles/PSKControlPlaneBaseRole]
        end
        subgraph oidc-provider
            ID[id-token]
        end
    end

    FW[AWS Firewall]
    NLB[Network Load Balancer]
    AUTH0[auth0.com tenant]
    RT@{ shape: brace-r, label: "automated
                                 rotation" }
    SA1@{ shape: rounded, label: "service account" }
    USER2((👤))
    SA2@{ shape: rounded, label: "system trust" }
    CLAIM@{ shape: brace-l, label: "claims: GitHub Teams
                                    map to role bindings" }
    
    style SA1 stroke:#306F00
    style USER2 stroke:#A06DA0
    style SA2 stroke:#106DA0

    linkStyle 1 stroke:#306F00,stroke-width:3px
    linkStyle 2 stroke:#306F00,stroke-width:3px
    linkStyle 3 stroke:#306F00,stroke-width:3px

    linkStyle 4 stroke:#A06DA0,stroke-width:3px
    linkStyle 5 stroke:#A06DA0,stroke-width:3px
    linkStyle 6 stroke:#A06DA0,stroke-width:3px
    linkStyle 7 stroke:#A06DA0,stroke-width:3px
    
    linkStyle 9 stroke:#106DA0,stroke-width:3px,stroke-dasharray:5 5
    linkStyle 10 stroke:#106DA0,stroke-width:3px,stroke-dasharray:5 5
    linkStyle 11 stroke:#106DA0,stroke-width:3px,stroke-dasharray:5 5
    linkStyle 12 stroke:#106DA0,stroke-width:3px,stroke-dasharray:5 5

```
## Lab Instances
```mermaid
---
title: EKS multi-zone cluster
---
flowchart TD

    CPc --- CPb --- CPa --- EKS

    MgmtNodePoola --- MgmtNodePoolb --- MgmtNodePoolc --- |taint| Managed --- MTYPE
    EKS@{ shape: lin-rect, label: "EKS" }
    Managed@{ shape: rounded, label: "node.kubernetes.io/role: management" }
    MTYPE@{ shape: rounded, label: "arm64, min:1 max:3" }

    AmdNodePoola --- AmdNodePoolb --- AmdNodePoolc --- |node selector| AMD --- KTYPE
    ArmNodePoola --- ArmNodePoolb --- ArmNodePoolc --- |node selector| ARM --- KTYPE
    AMD@{ shape: rounded, label: "kubernetes.io/arch: amd64" }
    ARM@{ shape: rounded, label: "kubernetes.io/arch: arm64" }
    KTYPE@{ shape: rounded, label: "instance types: multi
                                    expire: 14days
                                    consolidate
                                    Pool limits: 80CPU, 320Gi" }
        
    subgraph aws control plane
        subgraph cp-zone-a
            CPc[[master-node-a]]
        end
        subgraph cp-zone-b
            CPb[[master-node-b]]
        end
        subgraph cp-zone-c
            CPa[[master-node-c]]
        end
    end

    subgraph EKS managed node group
        subgraph mgmt-zone-c
            MgmtNodePoolc@{ shape: procs, label: "managment node"}
        end
        subgraph mgmt-zone-b
            MgmtNodePoolb@{ shape: procs, label: "managment node"}
        end
        subgraph mgmt-zone-a
            MgmtNodePoola@{ shape: procs, label: "managment node"}
        end
    end

    subgraph karpenter node pools
        subgraph zone-c
            AmdNodePoolc@{ shape: procs, label: "Amd64 node"}
            ArmNodePoolc@{ shape: procs, label: "Arm64 node"}
        end
        subgraph zone-b
            AmdNodePoolb@{ shape: procs, label: "Amd64 node"}
            ArmNodePoolb@{ shape: procs, label: "Arm64 node"}
        end
        subgraph zone-a
            AmdNodePoola@{ shape: procs, label: "Amd64 node"}
            ArmNodePoola@{ shape: procs, label: "Arm64 node"}
        end
    end
```

A typical Engineering Platform release pipeline for the underlying cluster control plane instances will have the following cluster roles, following the VPC release path:
```mermaid
---
title: Typical Starting Platform Control Plane Path-to-Production
---
flowchart LR

    GITPUSH --> DEV
    GITMERGE --> QA
    GITTAG --> PREVIEW --> NONPROD --> PROD
    GITTAG --> MAPI

    DEV["Sandbox
        (Platform Eng Only)"]
    QA["QA
        (Platform Eng Only)"]
    PREVIEW["Preview
            (Developer Facing)"]
    MAPI["MAPI
            (Managment)"]
    NONPROD["Non-production
            (Developer Facing)"]
    PROD["Production
            (Developer Facing)"]

    GITPUSH@{ shape: brace-r, label: "$ git push _branch_" }
    GITMERGE@{ shape: brace-r, label: "$ git merge _main_" }
    GITTAG@{ shape: brace-r, label: "$ git tag _1.3.3_" }
```

At scale, each role may include multiple clusters. Note that the platform customer namespaces are limited to targeted roles that all amount to `production` from the platform product team's point of view.  
```mermaid
---
title: simplified lab pipeline
---
flowchart LR

    GITPUSH --> DEV
    GITTAG --> PROD

    DEV[sbx-i01-aws-us-east-1]
    PROD[prod-i01-aws-us-east-1]

    GITPUSH@{ shape: brace-r, label: "$ git push" }
    GITTAG@{ shape: brace-r, label: "$ git tag _1.3.3_" }
```

## EKS Best Practices Guides

See [implementation notes](doc/Essential-EKS-Best-Practices-Reference.md).  
See release pipelin artifacts for kube-bench scan results in pipeline artifacts.  

## Maintainers

**Release version tag based on Kubernetes version**  

The semantic tag  convention for the control_plane_base pipeline is to set the major and minor based on the kubernetes version. The patch octet is used for each additional incremental update.  

Example: The initial upgrade release tag for kubernetes v1.34 will be 1.34.0, with 1-x for subsequent changes released between then and the Kubernetes v1.35 release.  

**upgrade kubernetes and addon version**  

Change `kubernetes_version` in the environments json to initiate upgrade to new EKS version. Addons will automatically update to the correct, latest version with each pipeline run.  

Karpenter is pinned to a value in the tfvars file. Update the version to perform the helm upgrade after reviewing the upgrade requirements. The kube-bench test is currently pinned to a Aquasec kube-bench image in the deployment manifest. Ongoing benchmark assessment is performed by the Trivy operator.   

**node lifecycles**  

Cluster services run on the ARM-based management node group. This node group uses the `use_latest_ami_release_version` setting to refresh nodes to the newest AMI on a pipeline run if one is available.  

Karpenter node pools are configured to automatically replace nodes older than 7 days.  

**TODO**  

* Moving forward with using only a simple per-cluster observability solution in order to be able to support more thorough Starterkit examples. When that is in place, should see base-specific configuration managed here.
* eks-addons vpc-cni, ebs-csi, and efs-csi don't yet have a recommended pattern for using the pod identity manager method.
* The current Module-based node lifecycle for the management group (`use_latest_ami_release_version`) only replaces nodes when newer release version are available. This averages about 2-3 weeks per release. A more secure approach is to have a scheduled run (weekly or similar) where the managed node group for a zero-downtime replacement. The Terraform `taint` command can be used to mark the group for replace with the next TF apply, and there are other potential ways as well.
