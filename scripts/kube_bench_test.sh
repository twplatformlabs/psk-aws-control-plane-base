#!/usr/bin/env bash
set -eo pipefail

if kubectl get job kube-bench -n psk-system &>/dev/null; then
  echo "Found leftover kube-bench job, deleting..."
  kubectl delete job kube-bench -n psk-system --wait=true
fi

kubectl apply -f test/kube-bench/job-eks.yaml
sleep 30

kubectl logs -l job-name=kube-bench -n psk-system --tail=-1 > kube-bench.log
kubectl delete -f test/kube-bench/job-eks.yaml
