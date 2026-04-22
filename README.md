<div align="center">
	<p>
	<img alt="Thoughtworks Logo" src="https://raw.githubusercontent.com/twplatformlabs/static/master/psk_banner.png" width=800 />
	<h2>psk-aws-control-plane-base</h2>
	<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/github/license/twplatformlabs/psk-aws-control-plane-base"></a> <a href="https://aws.amazon.com"><img src="https://img.shields.io/badge/-deployed-blank.svg?style=social&logo=amazon"></a>
	</p>
</div>

This `control plane base` pipeline is effectively limited to all, and only, those components of EKS that are managed by AWS. Deployments, version changes, and removal of the associated resource belong to AWS in the shared-responsibility model of IaaS vendor managed services. The pipeline owner directs only 'when' such changes occur by specifying version changes in the environment configuration or other similar practices of notifying AWS of a change to be made.  

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

## AWS Managed EKS Control Plane
```mermaid
---
title: EKS Components
---
flowchart LR

    VPC --- IRSA
    DNS --- IRSA
    EBSCSI --> RWO --- IRSA
    EFSCSI --> RWM --- IRSA
    EVNT --> SQS --> KRPT
    LOGS --- LOGS1

    subgraph Control Plane Base
        subgraph Management Node Pool
            
            DNS[CoreDNS]
            EBSCSI[ebs-csi]
            EFSCSI[efs-csi]
            LOGS[Cloudwatch Logs]
            KRPT[Karpenter]
        end
        subgraph daemons
            KP[kube-proxy]
            VPC[vpc-cni]
        end
    end

    IRSA@{ shape: brace-l, label: "irsa roles" }
    RWO[(RW-One storageclass)]
    RWM[(RW-Many storageclass
         w/general mnt)]
    
    LOGS1@{ shape: brace-l, label: "api, audit, authenticator, controllerManager, scheduler" }
    SQS@{ shape: rounded, label: "SQS"}
    EVNT@{ shape: trap-b, label: "Event Bridge"}

```

* control plane logging default = "api", "audit", "authenticator", "controllerManager", "scheduler"
* control plan internals encrypted using aws managed kms key
* arm-based Managed Node Group for dedicated management pool with specific toleration requirements
* eks addons:
  * vpc-cni
  * coredns
  * kube-proxy
  * aws-ebs-csi-driver
		* default storage class target provisioned, by convention = `$cluster_name-ebs-csi-storage-class`
	* aws-efs-csi-driver
		* efs file share created
		* default storage class provisioned, by convention = `$cluster_name-efs-csi-storage-class`
		* filesystem-id stored in 1password, make discoverable via platforms/clusters API
	* karpenter
		* sqs and eventbridge managed disruption events
		* arm and amd NodePools resources defined
			* target desired architecture with `kubernetes.io/arch` = "arm64" | "amd64"
* psk-system namespace created
* admin ClusterRolebinding created for twplatformlabs/platform team claim

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

See [implementation notes](EKS-Best-Practices-Guides.md).  

## Maintainers

**upgrade kubernetes and addon version**  

Change `eks_version` in the environments json to initiate upgrade to new EKS version. Addons will automatically update to the correct, latest version with each pipeline run.  

**managment node group**  

The `taint` step results in the MNG nodes updating to the correct, latest patch version.  

**general data plane ndoes**  

Karpenter managed nodepools will schedule an update to the correct, latest patch version each week.  

**TODO**  

* observability solution to replace datadog not yet implemented
* eks-addons vpc-cni, ebs-csi, and efs-csi are not yet deployed using the pod identity manager method in the lastest module.
* currently the "taint" logic for refresh of management node group nodes is based on a value in the environment file. Which means that it is just on or off. The reason for this is that when creating a new cluster there are no node groups to taint so a command to do so will fail so you must set it true or false in the code based on the cluster (or cluster role if scaled). A better solution would be to have a test that can determine if the cluster does not yet exist and thereby skip the taint, successfully.

