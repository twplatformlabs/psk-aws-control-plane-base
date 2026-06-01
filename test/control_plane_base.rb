require 'awspec'
require 'json'

tfvars = JSON.parse(File.read('./' + ENV['CLUSTER'] + '.auto.tfvars.json'))

describe eks(tfvars["cluster_name"]) do
  it { should exist }
  it { should be_active }
  its(:version) { should eq tfvars['kubernetes_version'] }
end

describe efs(tfvars["cluster_name"] + "-efs-csi-storage") do
  it { should exist }
end

describe sqs("Karpenter-" + tfvars["cluster_name"]) do
  it { should exist }
end
