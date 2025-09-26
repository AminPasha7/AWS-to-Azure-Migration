param(
  [Parameter(Mandatory=$true)] [string] $AwsAccountId,
  [Parameter(Mandatory=$true)] [string] $Region,
  [Parameter(Mandatory=$true)] [string] $Repository,   # e.g. "demo" (no tag)
  [Parameter(Mandatory=$true)] [string] $Tag,          # e.g. "latest"
  [Parameter(Mandatory=$true)] [string] $AcrName       # e.g. "myacr" (no domain)
)

$ErrorActionPreference = "Stop"

# Compose endpoints
$ecr = "$AwsAccountId.dkr.ecr.$Region.amazonaws.com"
$acrLoginServer = (az acr show -n $AcrName --query loginServer -o tsv)

Write-Host "ECR: $ecr"
Write-Host "ACR: $acrLoginServer"

# Login to ECR
Write-Host "Logging in to ECR..."
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $ecr

# Login to ACR
Write-Host "Logging in to ACR..."
az acr login -n $AcrName | Out-Null

$src = "$ecr/$Repository`:$Tag"
$dst = "$acrLoginServer/$Repository`:$Tag"

Write-Host "Pulling $src ..."
docker pull $src

Write-Host "Retagging -> $dst ..."
docker tag $src $dst

Write-Host "Pushing $dst ..."
docker push $dst

Write-Host "Done. Image available at: $dst"
