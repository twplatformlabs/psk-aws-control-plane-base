#!/usr/bin/env bash
set -eo pipefail

kubectl apply -f test/kube-bench/job-eks.yaml
sleep 30

kubectl logs -l job-name=kube-bench -n psk-system --tail=-1 > kube-bench.log
kubectl delete -f test/kube-bench/job-eks.yaml
