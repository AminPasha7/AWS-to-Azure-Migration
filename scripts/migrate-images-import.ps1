param(
  [Parameter(Mandatory=$true)] [string] $AwsAccountId,   # e.g. 482325330651
  [Parameter(Mandatory=$true)] [string] $Region,         # e.g. us-east-1
  [Parameter(Mandatory=$true)] [string] $Repository,     # e.g. demo
  [Parameter(Mandatory=$true)] [string] $Tag,            # e.g. latest
  [Parameter(Mandatory=$true)] [string] $AcrName         # e.g. aws2azurepocacr
)

$ErrorActionPreference = "Stop"

$ecr = "$AwsAccountId.dkr.ecr.$Region.amazonaws.com"
$sourceRef = "$ecr/$Repository`:$Tag"

Write-Host "Importing $sourceRef -> ACR '$AcrName'..."

# Get a short-lived ECR password and feed to az acr import (username must be AWS)
$pwd = aws ecr get-login-password --region $Region
if (-not $pwd) { throw "Failed to get ECR password. Check AWS CLI auth and IAM permissions." }

# az acr import handles the copy inside Azure; no local Docker needed
az acr import `
  --name $AcrName `
  --source $sourceRef `
  --username AWS `
  --password $pwd `
  --image "$Repository`:$Tag" `
  --force

Write-Host "Done. Image available at: $(az acr show -n $AcrName --query loginServer -o tsv)/$Repository`:$Tag"
