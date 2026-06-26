#!/usr/bin/env bats

@test "validate nodes reporting" {
  run bash -c "kubectl get nodes | tail -n +2 | wc -l"
  [[ "${output}" != "0" ]]
}

@test "validate nodes Ready" {
  run bash -c "kubectl get nodes | grep 'Not Ready"
  [[ "${output}" != "Not Ready" ]]
}

@test "validate psk system namespace" {
  run bash -c "kubectl get ns"
  [[ "${output}" =~ "psk-system" ]]
}

@test "validate psk-adkmin clusterrolebinding" {
  run bash -c "kubectl get clusterrolebindings"
  [[ "${output}" =~ "psk-admin-clusterrolebinding" ]]
}

@test "validate cluster-info" {
  run bash -c "kubectl get clusterrolebindings"
  [[ "${output}" =~ "psk-admin-clusterrolebinding" ]]
}