param(
  [string]$Region = "us-east-1",
  [string]$ClusterName = "poc-eks"
)
aws eks update-kubeconfig --name $ClusterName --region $Region
kubectl cluster-info
