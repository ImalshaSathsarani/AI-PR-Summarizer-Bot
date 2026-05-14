# 🤖 AI Pull Request Summarizer

An automated DevOps tool that uses the Google Gemini AI API to generate concise and meaningful summaries for GitHub Pull Requests. This project demonstrates a production-grade GitOps workflow, moving from local development to a self-managed Kubernetes (K3s) cluster on AWS.

---

# 🏗️ System Architecture

The project follows a modern cloud-native architecture designed for scalability, automation, and security.

This project follows a modern, secure GitOps workflow. The diagram below illustrates how code changes trigger a continuous deployment pipeline into a self-managed, resource-optimized Kubernetes environment.

![System Architecture](/images/Architecture Diagram.png)

#### preview:

![Generated System Architecture Diagram](/images/Architecture Diagram.png)

## 🔄 Continuous Integration
- GitHub Actions automatically builds and tests the application on every push to the `main` branch.
- Docker images are created and versioned automatically.

## 📦 Secure Container Registry
- Docker images are securely stored in Amazon Elastic Container Registry (ECR).
- Versioned image tags allow rollback and deployment tracking.

## 🚀 Automated Deployment
- Deployments are triggered securely using AWS Systems Manager (SSM).
- No SSH access or open port `22` is required, reducing the server attack surface.

## ☸️ Kubernetes Orchestration
- A lightweight K3s Kubernetes cluster manages container deployment and lifecycle.
- Optimized to run efficiently on AWS Free Tier (`t3.micro`) instances.

---

# 🛠️ Tech Stack

| Category | Technologies |
|----------|--------------|
| Backend | Node.js, Express |
| AI Integration | Google Gemini Pro API |
| Infrastructure | Terraform, AWS EC2, ECR, IAM, SSM |
| Containerization | Docker |
| Orchestration | Kubernetes (K3s) |
| CI/CD | GitHub Actions |
| Configuration | YAML Manifests |

---

# 🌟 Key Features

## ✨ Automated Pull Request Summaries
Analyzes GitHub Pull Request diffs and generates human-readable summaries to improve developer productivity and speed up code reviews.

## 🔐 Zero-SSH Deployments
Uses AWS Systems Manager (SSM) for secure “keyless” deployments without exposing SSH ports.

## ⚡ Resource Optimized
Configured to run efficiently on low-resource AWS Free Tier instances using:
- Linux Swap Memory
- Lightweight K3s Kubernetes Cluster

## 🔑 Secure Secret Management
Sensitive credentials such as API keys and registry tokens are managed securely using Kubernetes Secrets.

---

# 📂 Project Structure

```bash
pr-summarizer-bot/
│
├── k8s/
│   ├── deployment.yaml
├
├── .github/
│   └── workflows/
│       └── deploy.yml
│
├── index.js
├── main.tf
├── terraform.tfvars
├── Dockerfile
├── package.json
└── README.md
