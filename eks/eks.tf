
module "use_eksClusterRole" {
  count  = var.use_predefined_role ? 1 : 0
  source = "./modules/use-service-role"

  cluster_role_name = var.cluster_role_name
}

module "create_eksClusterRole" {
  count  = var.use_predefined_role ? 0 : 1
  source = "./modules/create-service-role"

  cluster_role_name = var.cluster_role_name
  additional_policy_arns = [
    aws_iam_policy.loadbalancer_policy.arn
  ]
}

####################################################################
#
# Creates the EKS Cluster control plane
#
####################################################################

resource "aws_eks_cluster" "demo_eks" {
  name     = var.cluster_name
  role_arn = var.use_predefined_role ? module.use_eksClusterRole[0].eksClusterRole_arn : module.create_eksClusterRole[0].eksClusterRole_arn

  vpc_config {
    subnet_ids = [
      data.aws_subnets.public.ids[0],
      data.aws_subnets.public.ids[1],
      data.aws_subnets.public.ids[2]
    ]
  }

  access_config {
    authentication_mode                         = "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
}


resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.node_instance_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes"
        ]
      }
    ])
  }

  depends_on = [
    aws_eks_cluster.demo_eks
  ]
}

# Data sources and provider configuration to talk to the EKS control plane
# Use the cluster endpoint + IAM auth token instead of relying on a local kubeconfig
data "aws_eks_cluster" "demo" {
  name = aws_eks_cluster.demo_eks.name
}

data "aws_eks_cluster_auth" "demo" {
  name = aws_eks_cluster.demo_eks.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.demo.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.demo.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.demo.token
}

# Install common EKS addons after the cluster is ready
# These use the AWS EKS Addon API to manage core add-ons (no service account role specified).
# Create addons that have an explicit version pinned
resource "aws_eks_addon" "addons_with_version" {
  for_each      = { for k, v in local.eks_addons : k => v if v.version != "" }
  cluster_name  = aws_eks_cluster.demo_eks.name
  addon_name    = each.key
  addon_version = each.value.version
  depends_on    = [aws_eks_cluster.demo_eks]
}

# Create addons that don't specify a version (provider will install default/latest)
resource "aws_eks_addon" "addons_no_version" {
  for_each     = { for k, v in local.eks_addons : k => v if v.version == "" }
  cluster_name = aws_eks_cluster.demo_eks.name
  addon_name   = each.key
  depends_on   = [aws_eks_cluster.demo_eks]
}
