# Deploy sample app to EKS (no ELB cost)
kubectl apply -f ../k8s/demo.yaml
kubectl -n demo rollout status deploy/demo
kubectl -n demo get svc demo -o wide
Write-Host ""
Write-Host "Port-forward with:"
Write-Host "kubectl -n demo port-forward svc/demo 8080:80"
