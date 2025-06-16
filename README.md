# RDS Terraform Provisioning

This repository contains Terraform code for ad-hoc provisioning of Amazon RDS environments using AWS credentials provided at runtime. The module is designed to streamline setup in existing AWS environments by automating essential RDS components.

---

## 🔧 Features

- Provisions an Amazon RDS instance within a specified VPC and subnets
- Creates the following resources:
  - Security Group for database access
  - Secrets Manager secret for RDS username/password
  - DB Subnet Group
  - RDS Instance (based on provided configuration)

---

## 🛠️ Technology Used

- Terraform (HCL)

---

## 🚀 Getting Started

### Prerequisites

- An existing **VPC**, **subnets**, and **monitoring role**
- An **S3 bucket** set up for Terraform state and locking
- AWS credentials:
  - Access Key ID
  - Secret Access Key
  - Session Token

---

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/cwillis13/rds-terraform-provisioning.git
   cd rds-terraform-provisioning
   ```

2. **Initialize Terraform:**

   ```bash
   terraform init
   ```

3. **Plan the deployment:**

   ```bash
   terraform plan
   ```

4. **Apply the configuration:**

   ```bash
   terraform apply
   ```

   > 💡 Terraform will prompt you to enter your AWS Access Key ID, Secret Access Key, and Session Token at runtime.

---

## 🧪 Example Usage

```bash
terraform init
terraform plan
terraform apply
```

---
