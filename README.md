# assignment
This assignment provisions a secure, private EKS cluster with Terraform and sets up a full CI/CD flow using Jenkins, Kong API Gateway, and Helm.

Key Features

Infrastructure as Code (Terraform): Creates VPC, subnets, NAT, EKS cluster, and node groups.

Private EKS Cluster: API endpoint disabled for the internet (endpoint_public_access=false), accessible only within the VPC.

Jenkins on EKS: With persistent storage and RBAC (least privilege).

Kong Ingress Controller: Central API Gateway, routing based on hostnames.

Generic Helm Chart: Can deploy any API with configurable values.

Jenkins Pipeline (CI/CD): Builds Docker image, pushes to ECR, deploys via Helm, and exposes API through Kong.

🔹 High-Level Architecture
                ┌─────────────────────────────┐
                │        GitHub Repo           │
                └─────────────┬───────────────┘
                              │ Webhook
                              ▼
                      ┌──────────────┐
                      │   Jenkins     │
                      │   (EKS Pod)   │
                      └───────┬───────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │ Build & Push Image  │
                    │   (AWS ECR)         │
                    └─────────┬───────────┘
                              │
                              ▼
                      ┌──────────────┐
                      │   Helm Chart  │
                      │  (Deployment) │
                      └───────┬───────┘
                              │
                              ▼
                      ┌──────────────┐
                      │    API Pods   │
                      │ (in EKS)      │
                      └───────┬───────┘
                              │
                              ▼
                ┌─────────────────────────────┐
                │      Kong API Gateway        │
                │ (Ingress Controller + LB)    │
                └─────────────────────────────┘

🔹 Components
1. Infrastructure (Terraform)

New VPC with 3 private + 3 public subnets across AZs.

NAT Gateway for private subnet internet access.

Private EKS cluster (endpoint_public_access=false, endpoint_private_access=true).

Worker nodes in private subnets.

2. Jenkins on EKS

Deployed with PersistentVolumeClaim for durability.

Exposed via Kong Ingress (jenkins.polaris.com).

RBAC: Namespace-scoped Role instead of cluster-admin (least privilege).

3. Kong API Gateway

Installed via Helm, runs as Ingress Controller.

Exposed via AWS Load Balancer → routes traffic by hostname.

Example mappings:

jenkins.polaris.com → Jenkins service

api.polaris.com → Sample API service

4. Generic Helm Chart

Located in helmapideployment/.

Configurable parameters:

image.repository, image.tag, replicas, resources, ingress.host.

Includes liveness/readiness probes, resource limits, and optional imagePullSecrets.

5. Jenkins Pipeline

Defined in pipeline/Jenkinsfile.

Stages:

Checkout Code

Docker Build

Push to ECR

Configure kubeconfig (aws eks update-kubeconfig)

Helm Deploy API

Auto-trigger via GitHub webhook.

🔹 Validation

Check cluster is private

aws eks describe-cluster --name polaris-eks-cluster \
  --query "cluster.{public:endpointPublicAccess,private:endpointPrivateAccess}"
# Expected → public=false, private=true


Get Kong external LB

kubectl get svc -n kong kong-proxy


Update /etc/hosts (for testing locally)

<EXTERNAL-IP> api.polaris.com jenkins.polaris.com


Access Jenkins

http://jenkins.polaris.com


Test API after pipeline run

curl http://api.polaris.com/health

Security Highlights

Private EKS API endpoint.

Least-privilege RBAC for Jenkins.

IAM Roles for EKS nodes (no hardcoded credentials).

Persistent storage for Jenkins.


Automate DNS via Route53 instead of manual /etc/hosts.
