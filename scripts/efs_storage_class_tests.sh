#!/usr/bin/env bash
set -eo pipefail

cluster_name=$1
export AWS_REGION=$(jq -er .aws_region "$cluster_name".auto.tfvars.json)
efs_eks_cis_storage_id=$(op read op://platform/$cluster_name/eks-efs-csi-storage-id)

# Clean up any leftover artifacts from a previous failed run
echo "Checking for orphaned efs csi storage test artifacts from previous run..."

# Dynamic volume resources
if kubectl get pvc efs-claim -n psk-system &>/dev/null; then
  echo "Found leftover PVC efs-claim, deleting..."
  kubectl delete pod dynamic-volume-test-pod -n psk-system --ignore-not-found --wait=false
  kubectl delete pod -l app=multi-write-test -n psk-system --ignore-not-found --wait=false
  kubectl delete pvc efs-claim -n psk-system --wait=true
fi

# Static PV from multi-write test (Retain policy — won't self-delete)
if kubectl get pv efs-pv &>/dev/null; then
  echo "Found leftover PV efs-pv, deleting..."
  kubectl delete pv efs-pv --wait=true
fi

echo "Pre-flight cleanup complete."

# create efs dynamic persistent volume claim
cat <<EOF > test/efs/dynamic-volume/pvc.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
  namespace: psk-system
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: $cluster_name-efs-csi-dynamic-storage
  resources:
    requests:
      storage: 5Gi
EOF
kubectl apply -f test/efs/dynamic-volume/pvc.yaml
kubectl apply -f test/efs/dynamic-volume/dynamic-volume-test-pod.yaml

# test efs dynamic persistent volume claim
sleep 30
bats test/efs/dynamic-volume/dynamic-volume-test.bats
kubectl delete -f test/efs/dynamic-volume/dynamic-volume-test-pod.yaml
kubectl delete -f test/efs/dynamic-volume/pvc.yaml

# test multi-write volume
cat <<EOF > test/efs/multi-write/pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
  namespace: psk-system
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: $cluster_name-efs-csi-dynamic-storage
  resources:
    requests:
      storage: 5Gi

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv
  namespace: psk-system
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: $cluster_name-efs-csi-dynamic-storage
  csi:
    driver: efs.csi.aws.com
    volumeHandle: $efs_eks_cis_storage_id
EOF
kubectl apply -f test/efs/multi-write/pvc.yaml
kubectl apply -f test/efs/multi-write/multi-write-test-pods.yaml
sleep 30
bats test/efs/multi-write/multi-write-test.bats

kubectl delete -f test/efs/multi-write/multi-write-test-pods.yaml
kubectl delete -f test/efs/multi-write/pvc.yaml
