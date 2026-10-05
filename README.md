# Multi-AZ Serverless Container Platform Architecture (AWS & Terraform)

## 🏗️ Architectural Overview
This repository contains an enterprise-grade, highly available, and secure infrastructure blueprint managed entirely via a GitOps CI/CD workflow framework. The core system design isolates high-performance containerized microservices within a custom multi-tier Virtual Private Cloud (VPC) topology, mitigating perimeter vulnerabilities and ensuring automated runtime recovery.

## 🛠️ Core Competencies & Tech Stack
* **Infrastructure as Code (IaC):** Terraform (CLI v1.7.0+) leveraging component modularization best practices.
* **Orchestration & Compute:** Amazon ECS (Elastic Container Service) running serverless **AWS Fargate** processing cells.
* **CI/CD Automation Engine:** GitHub Actions orchestrating automated environment verification and policy enforcement.
* **Networking Tier:** Custom VPC architecture, Multi-Availability Zone public/private subnet matrices, Edge Internet Gateways, and isolated NAT Gateway fabrics.
* **State Governance & Security:** Distributed multi-user concurrency tracking using **Amazon DynamoDB** hash locking with state encryption (`AES-256`) backed by **Amazon S3**.



## 🔒 Production Design Choices Explained

### 1. Zero-Trust Network Isolation
The active runtime container tasks are deployed strictly within deep **Private Workload Subnets** (`10.0.11.0/24` and `10.0.12.0/24`) with all direct inbound internet routing blocked at the network perimeter. Inbound accessibility is governed via a strict security group mesh: containers only permit entry requests on port 80 if the request explicitly originates from the public-facing Application Load Balancer’s security group token.

### 2. High Availability & Automated Self-Healing
Workload cells are systematically distributed across independent AWS Availability Zones (`ap-south-1a` and `ap-south-1b`). Backed by an ECS Service engine configuration tracking an active `desired_count = 2`, the cloud platform automatically monitors node health via target group pings. If an entire zone location suffers an infrastructure failure, the manager marks the affected cell anomalous and seamlessly shifts load traffic to the healthy zone while spinning up an identical replacement instance in seconds.

### 3. Compliant State Locking Architecture
To simulate collaborative enterprise environments, state snapshots are decoupled from the local computer and recorded inside an encrypted S3 bucket featuring continuous object versioning. Concurrency race conditions are fully eliminated via a DynamoDB `LockID` primary key system. Any duplicate execution attempts triggered simultaneously are instantly dropped by the database lock, guaranteeing zero state configuration corruption or architectural drift.