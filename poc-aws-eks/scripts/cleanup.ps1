# Tears down the entire PoC (be sure you are in the right directory!)
$TerraformDir = Join-Path (Split-Path $PSScriptRoot -Parent) "infra/terraform"
Push-Location $TerraformDir
try {
  kubectl delete -f ../../k8s/demo.yaml --ignore-not-found | Out-Null
  terraform destroy -auto-approve
} finally {
  Pop-Location
}
