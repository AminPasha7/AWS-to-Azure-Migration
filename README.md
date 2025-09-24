# AWS → Azure Migration PoC

This repository demonstrates a **production-style Proof of Concept (PoC)** for migrating a containerized workload from **AWS (EKS + ECR)** to **Azure (AKS + ACR)**.  

It provides a minimal but realistic setup that shows how infrastructure and workloads can be lifted, shifted, and re-deployed across cloud providers using **Terraform**, **Helm**, and **Kubernetes manifests**.  

---

## 📊 Architecture Overview

![AWS → Azure Migration PoC](./docs/aws%20to%20azure%20migration%20poc.png)

### Explanation
- **AWS Side (Source)**
  - **VPC + Subnets**: Public & private networking, NAT, and IGW.
  - **EKS Cluster**: Kubernetes cluster with CPU node group (`t3.medium`) and GPU node group (`p3.2xlarge`, scaled to 0 by default to avoid cost).
  - **ECR Repository**: Stores application container images, secured with lifecycle policies to clean up untagged images.
  - **CloudWatch Logs**: Collects audit and cluster activity logs.

- **Azure Side (Target)**
  - **VNet + Subnets**: Networking equivalent of the AWS VPC.
  - **AKS Cluster**: Kubernetes cluster with CPU node pool and GPU pool (scaled to 0 initially).
  - **ACR Repository**: Container registry for storing and securing images after migration.
  - **Azure Monitor / Sentinel**: Observability, audit logging, and compliance monitoring.
  - **Entra ID (AAD)**: Identity and RBAC integration for secure access.

- **Migration Flow**
  1. Container image is pushed to **AWS ECR** and deployed to EKS.  
  2. The same image is retagged and pushed to **Azure ACR**.  
  3. Kubernetes manifests/Helm charts are applied to **AKS** with minimal changes.  
  4. Logs, monitoring, and RBAC are validated on Azure.  
  5. AWS resources are torn down after PoC validation.  

---

## 🎯 Objectives
- Show a realistic **cloud-native migration workflow** between AWS and Azure.  
- Demonstrate **portability** of Kubernetes manifests and Helm charts.  
- Implement **SOC2-aligned security controls**: logging, monitoring, RBAC, IP protection.  
- Provide **infrastructure as code (Terraform)** for easy provisioning and cleanup.  

---

## 🏗️ AWS Components
- **VPC + Subnets** (public/private, IGW, NAT)
- **EKS Cluster**: CPU node group (`t3.medium`), GPU node group (`p3.2xlarge`, desired=0)
- **ECR**: Image repository with lifecycle policy
- **CloudWatch Logs**

## ☁️ Azure Components
- **VNet + Subnets**
- **AKS Cluster**: CPU pool, GPU pool (desired=0)
- **ACR**
- **Azure Monitor / Sentinel**
- **Entra ID Integration**

---

## 🚀 Usage

### AWS (Source)
```powershell
cd poc-aws-eks/infra/terraform
terraform init
terraform apply -auto-approve

..\..\scripts\eks-get-kubeconfig.ps1
..\..\scripts\deploy-sample.ps1
kubectl -n demo port-forward svc/demo 8080:80
```

### Azure (Target – coming soon)
```powershell
cd poc-azure-aks/infra/terraform
terraform init
terraform apply -auto-approve
```

---

## 🔄 Migration Demo (ECR → ACR)
```bash
# 1. Authenticate to both registries
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.us-east-1.amazonaws.com
az acr login --name <acr_name>

# 2. Pull from ECR
docker pull <aws_account_id>.dkr.ecr.us-east-1.amazonaws.com/demo:latest

# 3. Retag for ACR
docker tag <aws_account_id>.dkr.ecr.us-east-1.amazonaws.com/demo:latest <acr_name>.azurecr.io/demo:latest

# 4. Push to ACR
docker push <acr_name>.azurecr.io/demo:latest

# 5. Update manifests and apply on AKS
kubectl apply -f k8s/demo.yaml --context=azure-aks
```

---

## 🧹 Cleanup
```powershell
poc-aws-eks/scripts/cleanup.ps1
poc-azure-aks/scripts/cleanup.ps1
```

---

## 📌 Notes
- EKS control plane incurs cost (~$74/month) even without worker nodes → destroy ASAP after testing.  
- GPU node groups are defined but kept at **scale=0** to avoid cost.  
- Designed for **testing, migration PoC, and learning**, not production workloads.  
