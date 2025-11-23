# Install Helm-managed releases (ingress-nginx and Argo CD) using the Terraform Helm provider
# This file expects `data.aws_eks_cluster.demo` and `data.aws_eks_cluster_auth.demo` to be present
# and `aws_eks_cluster.demo_eks` to exist in the same module (they are defined in `eks.tf`).

locals {
  ingress_namespace = "ingress-nginx"
  argocd_namespace  = "argocd"
  ingress_release   = "ingress-nginx"
  argocd_release    = "argocd"
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.demo.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.demo.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.demo.token
  }
}

# NGINX Ingress Controller (Helm chart)
resource "helm_release" "ingress_nginx" {
  name       = local.ingress_release
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = local.ingress_namespace

  create_namespace = true
  wait             = true
  timeout          = 600

  # Example: override values if needed
  # values = [file("./helm/ingress-values.yaml")]

  depends_on = [aws_eks_cluster.demo_eks]
}

# Argo CD (Helm chart from argo-helm)
resource "helm_release" "argocd" {
  name       = local.argocd_release
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = local.argocd_namespace

  create_namespace = true
  wait             = true
  timeout          = 600

  # Example: override values for argocd via a values file
  # values = [file("./helm/argocd-values.yaml")]

  depends_on = [aws_eks_cluster.demo_eks]
}
