# 🏦 DevSecOps Banking Microservices: Infrastructure & CI/CD Pipeline

![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Security](https://img.shields.io/badge/Security-Shift--Left-red)

> **Note:** For details regarding the application architecture, microservices logic, and API interactions, please refer to the [Application Documentation (README_APP.md)](./README_APP.md).
>
> For Continuous Deployment (ArgoCD) and Observability (PLG stack) configurations, visit the companion GitOps repository: [banking-gitops](link-to-your-gitops-repo).

This repository contains the **Infrastructure as Code (IaC)** and **Continuous Integration (CI)** implementations for a highly available, event-driven banking application deployed on Amazon Web Services (AWS). It demonstrates a complete, automated DevSecOps lifecycle with a strong emphasis on security, FinOps, and scalable cloud architecture.

---

## 🏗️ Cloud Infrastructure (Terraform)

The infrastructure is entirely provisioned using **Terraform**, modularized for reusability, and managed centrally via **HCP Terraform** to ensure state locking and secure variable management.

### Architecture Highlights
* **VPC & Networking:** A strict 4-subnet topology across 2 Availability Zones (Multi-AZ). The EKS compute nodes and all databases are completely isolated in **Private Subnets** to minimize the attack surface.
* **Compute (Amazon EKS):** Managed Node Groups running Kubernetes.
* **AWS Managed Databases:** To prevent data loss during pod crashes, all stateful workloads are offloaded to AWS managed services:
  * **Amazon RDS (PostgreSQL):** Core relational database for transactional integrity (ACID).
  * **Amazon ElastiCache (Redis):** Distributed session caching.
  * **Amazon DocumentDB:** MongoDB-compatible store for unstructured audit logs.
  * **Amazon MQ:** Message broker handling asynchronous logging.

### 💰 FinOps & Environment Parity Strategies
The infrastructure is dynamically adapted based on the environment to balance Cost Optimization (Staging) and Fault Tolerance (Production):

| Component | Staging (FinOps Optimized) | Production (High Availability) |
| :--- | :--- | :--- |
| **NAT Gateway** | Single NAT Gateway (reduces cost by 50%) | 1 NAT Gateway per AZ |
| **RDS PostgreSQL** | Single-Instance | `multi_az = true` (Auto-failover) |
| **ECR Image Tags** | `MUTABLE` (allows rapid CI overwrites) | `IMMUTABLE` (protects release integrity)|
| **Secrets Manager** | Recovery Window = `0 days` (instant wipe) | Recovery Window = `7 days` |
| **EKS Nodes** | `t3.medium` (Min: 1, Max: 4) | `t3.large` (Min: 2, Max: 6) |

---

## 🛡️ CI/CD Pipeline & Shift-Left Security

The Continuous Integration pipeline is orchestrated by **GitHub Actions**, executing parallel jobs to strictly validate code and container images before they reach the registry.

### 1. Shift-Left Security Gates
Before any image is pushed to Amazon ECR, it must pass 4 rigorous security checkpoints:
1. **Gitleaks (Secret Scanning):** Scans the entire commit history to block hardcoded credentials, API keys, or webhooks.
2. **SonarCloud (SAST):** Performs static code analysis with JaCoCo integration, enforcing a strict **Quality Gate (>70% Code Coverage)**.
3. **Container Security (Multi-stage Build):** Dockerfiles are heavily optimized using multi-stage builds. Runtime containers use stripped-down JRE images and are forced to execute under an unprivileged `appuser` (non-root).
4. **Trivy (Vulnerability Scanner):** Scans the built container layers for CVEs (High/Critical) before authorizing the push to ECR.

### 2. Deployment Workflows (CI to CD Handoff)

* **`ci-main.yml` (Staging):** Triggers on pushes to the `main` branch. 
  * Detects changed microservices.
  * Runs Unit Tests & Integration Smoke Tests (Docker Compose).
  * Builds, scans, and pushes images to ECR.
  * *GitOps Handoff:* Automatically commits the new Image SHA tag directly to the GitOps repository for instant ArgoCD synchronization.

* **`ci-production.yml` (Production):** Triggers on PR merges to the `production` branch.
  * **Image Promotion:** Does *not* rebuild code. It securely promotes (copies) the exact immutable, tested image from the Staging ECR to the Production ECR.
  * **PR Handoff:** Creates a Pull Request in the GitOps repository. Production deployment only occurs after a human engineer approves and merges this PR.

### 3. Infrastructure Lifecycle Automation
To support testing without incurring idle cloud costs, automated Bootstrap and Teardown workflows are implemented:
* **`infra-staging-up.yml`:** Initializes the EKS cluster post-Terraform. It automatically configures `kubeconfig`, installs the AWS Load Balancer Controller, HashiCorp Vault, External Secrets Operator (ESO), and bootstraps ArgoCD via the `cluster-reviver.sh` script.
* **`infra-staging-down.yml`:** Safely tears down the CD stack before Terraform destruction. It halts ArgoCD syncs, uninstalls controllers, and actively releases AWS Load Balancers to prevent infrastructure deadlock during `terraform destroy`.

---

## 🚀 Getting Started

### Prerequisites
* Terraform >= 1.5.0 & HCP Terraform Account
* AWS CLI configured with appropriate IAM permissions
* GitHub Secrets configured (e.g., `SONAR_TOKEN`, `OIDC_ROLE_ARN`)

### Provisioning Infrastructure
```bash
cd terraform/environments/staging
terraform init
terraform plan -var-file="staging.tfvars"
terraform apply -var-file="staging.tfvars"
```
After provisioning, trigger the infra-staging-up.yml GitHub Action manually to bootstrap the cluster controllers and GitOps engine.
