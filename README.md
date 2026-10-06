# AWS ECS Fargate and PostgreSQL Infrastructure

This repository contains Terraform configuration for a small AWS web stack. It creates a VPC, an internet-facing Application Load Balancer (ALB), an ECS Fargate service running the stock `nginx:alpine` image, and a PostgreSQL RDS instance.

This is a starter/demo configuration, not a production-ready application. Review the security and availability notes below before deploying it to an AWS account.

## Architecture


```mermaid
flowchart TD
    Internet([Global Internet]) --> WAF
    
    subgraph VPC [Custom VPC: 10.0.0.0/16]
        subgraph DMZ [Public DMZ Subnets]
            WAF["AWS WAFv2 Web ACL"] --> ALB["Public ALB (HTTP :80)"]
            NAT["Single NAT Gateway"]
        end

        subgraph Private [Private App Subnets]
            ALB --> ECS["ECS Fargate Service (2 Tasks)"]
        end

        subgraph Data [Isolated Data Subnets]
            ECS --> DB["RDS PostgreSQL (db.t3.micro)"]
        end
    end

    ECS -->|Outbound Image Pull| NAT
    NAT -->│Egress│ Internet
```

The VPC module defines public and private subnets from the CIDR lists in the root `main.tf`. It also creates two database subnets using `10.0.21.0/24` and `10.0.22.0/24`. Subnets are assigned to the first available AZs returned by AWS in the configured region; the AZ names are not hard-coded.

The ALB listener accepts HTTP on port 80 and forwards requests to the ECS service. A WAFv2 web ACL is associated with the ALB. The ECS task security group allows inbound port 80 from the ALB security group, and the database security group allows PostgreSQL port 5432 from the ECS task security group.

## What the configuration creates

- A custom VPC with public, private, and database subnets.
- One NAT Gateway in the first public subnet. Both private subnets use a shared private route table that routes outbound traffic through this gateway.
- An internet-facing ALB with an HTTP listener and target group health checks on `/`.
- An ECS cluster and Fargate service with `desired_count = 2`, using the `nginx:alpine` image.
- A WAFv2 web ACL with the AWS Common Rule Set and an IP-based rate-based rule configured with a limit of 500 requests.
- A CloudWatch log group for ECS logs with seven-day retention.
- One PostgreSQL 15.19 RDS instance using class `db.t3.micro` and 20 GiB of allocated storage.
- An S3 Terraform backend configured for encryption and DynamoDB state locking.

## Important limitations and deployment cautions

- **Database password input:** The RDS password is declared as a sensitive Terraform variable. The GitHub Actions workflow maps the GitHub secret `DB_PASSWORD` to Terraform's `TF_VAR_db_password` environment variable. Configure `DB_PASSWORD` as a GitHub Actions secret (repository or `prod` environment); never put its value in this README or commit it to the repository.
- **Terraform state contains secrets:** Marking a variable `sensitive` hides it from normal Terraform output, but does not prevent the database password from being stored in Terraform state. Restrict access to the state bucket and its backups. The S3 backend enables encryption, but state access should still be treated as access to secrets.
- **The database is a single instance.** A subnet group spans two AZs, but the RDS instance does not enable Multi-AZ deployment. This does not provide database failover across AZs.
- **Two desired tasks do not guarantee one task per AZ.** The service uses both private subnets, but the configuration does not enforce an even placement across AZs.
- **There is one NAT Gateway.** It is a single point of egress and may be a cross-AZ dependency for workloads in the other AZ. It is not a highly available NAT design.
- **The ALB only serves HTTP.** No HTTPS listener or TLS certificate is configured.
- **S3 versioning is not configured here.** Enable bucket versioning separately if state history and recovery are required. The backend configuration uses a DynamoDB lock table.
- **The GitHub Actions workflow applies on pushes to `main`.** Configure repository/environment protections, AWS credentials, and review requirements carefully before enabling it.
- **The application is only the stock Nginx image.** It does not deploy application code or connect the web container to the database.

## Repository layout

```text
.
├── .github/
│   └── workflows/
│       └── terraform.yml
├── backend.tf
├── main.tf
├── variables.tf
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── ecs/
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    └── rds/
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```

## Requirements

- Terraform version `1.5.0` or later.
- AWS credentials with permission to create the configured resources.
- An existing S3 bucket and DynamoDB table for the Terraform backend, as specified in `backend.tf`.
- GitHub Actions secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `DB_PASSWORD` if using the workflow. The workflow passes `DB_PASSWORD` to Terraform as `TF_VAR_db_password`.

The provider and workflow currently target `ap-south-1`. Update the provider/workflow configuration together if deploying in another region.

## Run Terraform locally

From the repository root:

```sh
terraform init
terraform fmt -check
terraform validate
terraform plan
```

For local plan or apply operations, also provide the database password through the `TF_VAR_db_password` environment variable using your preferred secure local secret-management method. Do not put the password directly in a command that may be saved in shell history.

Review the plan and make sure the backend, AWS account, region, and credentials are correct before deploying:

```sh
terraform apply
```

The GitHub Actions workflow runs formatting, initialization, and planning for pushes and pull requests targeting `main`. It runs `terraform apply -auto-approve` for pushes to `main`.
