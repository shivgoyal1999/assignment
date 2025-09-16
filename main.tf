module "vpc" {
  source = "./modules/vpc"

  vpc_cidr        = "10.0.0.0/16"
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

module "eks" {
  source = "./modules/eks"

  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}

module "nodegroup" {
  source = "./modules/nodegroup"

  cluster_name    = module.eks.cluster_name
  node_group_name = "polaris-ng"
  subnets         = module.vpc.private_subnets
}
