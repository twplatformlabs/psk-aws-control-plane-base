#!/usr/bin/env bash
set -eo pipefail
source bash-functions.sh

cluster_name=$1
trivy_operator_chart_version=$(jq -er .trivy_operator_chart_version $cluster_name.auto.tfvars.json)
echo "trivy operator chart version $trivy_operator_chart_version"

helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm repo update

# perform trivy scan of chart with install configuration
trivyScan "aqua/trivy-operator" "trivy-operator" "$trivy_operator_chart_version" "trivy-operator-values/$cluster_name-values.yaml"

helm upgrade --install trivy-operator aqua/trivy-operator \
             --version $trivy_operator_chart_version \
             --namespace psk-system \
             --values trivy-operator-values/$cluster_name-values.yaml
