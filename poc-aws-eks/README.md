AWS PoC for Migration (VPC + EKS + ECR)
=======================================

Minimal but realistic AWS stack you can later migrate to Azure AKS/ACR.

What it creates
- VPC (10.0.0.0/16), 2 public + 2 private subnets, IGW, NAT
- EKS Cluster with:
  - CPU node group: t3.medium (desired=1)
  - GPU node group defined (p3.2xlarge) with desired=0 (no cost until scaled)
- ECR repo with lifecycle policy (untagged images expire after 7 days)
- CloudWatch control-plane logs for EKS

Quick start
1) cd infra/terraform
2) terraform init
3) terraform apply -auto-approve
4) Run scripts/eks-get-kubeconfig.ps1
5) Run scripts/deploy-sample.ps1
6) kubectl -n demo port-forward svc/demo 8080:80  (open http://localhost:8080)

Clean up
- scripts/cleanup.ps1

Cost note
- EKS control plane (~$74/mo) + 1Ã— t3.medium (~$0.0416/hr). Keep up only while testing, then destroy.
