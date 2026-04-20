#!/usr/bin/env bash
set -eo pipefail

cluster_name=$1
export AWS_REGION=$(jq -er .aws_region "$cluster_name".auto.tfvars.json)

# Clean up any leftover artifacts from a previous failed run
echo "Checking for orphaned ebs csi storage test artifacts from previous run..."

# Dynamic volume resources
if kubectl get pvc test-ebs-claim -n psk-system &>/dev/null; then
  echo "Found leftover PVC test-ebs-claim, deleting..."
  kubectl delete pod dynamic-volume-test-pod -n psk-system --ignore-not-found --wait=false
  kubectl delete pvc test-ebs-claim -n psk-system --wait=true
fi

# Block volume resources
if kubectl get pvc test-block-claim -n psk-system &>/dev/null; then
  echo "Found leftover PVC test-block-claim, deleting..."
  kubectl delete pod block-volume-test-pod -n psk-system --ignore-not-found --wait=false
  kubectl delete pvc test-block-claim -n psk-system --wait=true
fi

# Any orphaned PVs in Released state bound to these claims
for pv in $(kubectl get pv -o jsonpath='{range .items[?(@.spec.claimRef.namespace=="psk-system")]}{.metadata.name}
{.status.phase}{"\n"}{end}' 2>/dev/null | awk '$2=="Released"{print $1}'); do
  echo "Found orphaned PV $pv in Released state, deleting..."
  kubectl delete pv "$pv"
done

echo "Pre-flight cleanup complete."

# create ebs-csi dynamic persistent volume claim
cat <<EOF > test/ebs/dynamic-volume/pvc.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-ebs-claim
  namespace: psk-system
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: $cluster_name-ebs-csi-dynamic-storage
  resources:
    requests:
      storage: 4Gi
EOF
kubectl apply -f test/ebs/dynamic-volume/pvc.yaml

# test persistent volume claim
kubectl apply -f test/ebs/dynamic-volume/dynamic-volume-test-pod.yaml
sleep 30
bats test/ebs/dynamic-volume/initial-pvc-test.bats

# expand dynamic volume size
cat <<EOF > test/ebs/dynamic-volume/pvc.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-ebs-claim
  namespace: psk-system
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: $cluster_name-ebs-csi-dynamic-storage
  resources:
    requests:
      storage: 8Gi
EOF
kubectl apply -f test/ebs/dynamic-volume/pvc.yaml

# test expanded persistent volume claim
sleep 90
bats test/ebs/dynamic-volume/expanded-pvc-test.bats

kubectl delete -f test/ebs/dynamic-volume/dynamic-volume-test-pod.yaml
kubectl delete -f test/ebs/dynamic-volume/pvc.yaml

# create ebs-csi block-mode persistent volume claim
cat <<EOF > test/ebs/block-volume/pvc.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-block-claim
  namespace: psk-system
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Block
  storageClassName: $cluster_name-ebs-csi-dynamic-storage
  resources:
    requests:
      storage: 4Gi
EOF
kubectl apply -f test/ebs/block-volume/pvc.yaml

# test block-mode volume
kubectl apply -f test/ebs/block-volume/block-volume-test-pod.yaml
sleep 45
bats test/ebs/block-volume/block-volume-claim-test.bats

kubectl delete -f test/ebs/block-volume/block-volume-test-pod.yaml
kubectl delete -f test/ebs/block-volume/pvc.yaml