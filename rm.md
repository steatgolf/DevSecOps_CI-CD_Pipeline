# FastAPI Application with DevSecOps on AWS using GitHub Actions

This project demonstrates a secure CI/CD pipeline for a FastAPI application deployed on AWS EC2 using Terraform for infrastructure management and GitHub Actions for automation. The pipeline incorporates various security scanning tools (SAST, SCA, Image Scanning, DAST) following DevSecOps best practices.

## Table of Contents

1.  [Overview](#overview)
2.  [Infrastructure Provisioning (Terraform)](#1-infrastructure-provisioning-terraform)
3.  [EC2 Instance Setup](#2-ec2-instance-setup)
4.  [CI/CD Pipeline (GitHub Actions)](#3-cicd-pipeline-github-actions)
5.  [Infrastructure Cleanup](#4-infrastructure-cleanup-terraform)
6.  [Prerequisites](#prerequisites)
7.  [Setup](#setup)
    * [Configure AWS Credentials](#configure-aws-credentials)
    * [Configure Repository Secrets](#configure-repository-secrets)
    * [Configure Terraform Variables](#configure-terraform-variables)
    * [Initialize Terraform](#initialize-terraform)
8.  [Usage](#usage)
    * [Provision Infrastructure](#provision-infrastructure-first-time)
    * [Develop & Push](#develop--push)
    * [Monitor Pipeline](#monitor-pipeline)
    * [Review Reports](#review-reports)
    * [Access Application](#access-application)
    * [Test CI/CD Pipeline](#test-cicd-pipeline)
    * [Destroy Infrastructure](#destroy-infrastructure)


## Overview

The goal of this project is to establish a robust and secure workflow for developing, testing, scanning, and deploying a FastAPI application.

* **Infrastructure as Code (IaC):** Terraform is used to define and manage AWS resources (VPC, Subnets, Security Groups, EC2, ECR).
* **CI/CD Automation:** GitHub Actions orchestrates the entire process from code commit to deployment.
* **DevSecOps Integration:** Security checks are embedded throughout the pipeline:
    * **SAST:** SonarQube analyzes static code for vulnerabilities.
    * **SCA:** Snyk scans dependencies for known vulnerabilities.
    * **Image Scanning:** Trivy scans the Docker image for OS and library vulnerabilities.
    * **DAST:** OWASP ZAP scans the running application for runtime vulnerabilities.
* **Secure Deployment:** Deployment to EC2 is handled via AWS Systems Manager (SSM) Run Command, eliminating the need for SSH keys.
* **Secure Containerization:** The Docker image is built using a non-root user to minimize potential container security risks.

## 1. Infrastructure Provisioning (Terraform)

Terraform (`main.tf`, `variables.tf`, etc. within a `terraform/` directory) is responsible for creating the necessary AWS infrastructure:

* **Networking:** VPC, Public/Private Subnets, Internet Gateway, NAT Gateway, Route Tables.
* **Compute:** EC2 Instance with an appropriate IAM Role allowing SSM access and ECR pull permissions.
* **Container Registry:** Elastic Container Registry (ECR) repository to store the Docker image.
* **Security:** Security Groups to control traffic to the EC2 instance.

**Deployment Strategy:**
Initially, Terraform can be configured to deploy a placeholder or initial version of the application using an `aws_ssm_document` and `aws_ssm_association` or by triggering an SSM Run Command via a `local-exec` provisioner after the EC2 instance is ready. However, the primary deployment mechanism is handled by the GitHub Actions pipeline after the image is built and pushed. Terraform outputs will provide necessary values like `EC2_INSTANCE_ID` and `EC2_IP`.

## 2. EC2 Instance Setup

After the EC2 instance is created by Terraform, a `remote-exec` or `user_data` script is used to provision the instance with necessary software:

* **Docker Engine:** To run the containerized FastAPI application.
* **AWS CLI:** To interact with AWS services if needed (though SSM reduces direct CLI dependency for deployment).

*Note:* Using SSM Agent (pre-installed on most recent AMIs) and Run Command for deployment is preferred over SSH-based provisioning for enhanced security. Ensure the EC2 instance's IAM role has the `AmazonSSMManagedInstanceCore` policy attached.

## 3. CI/CD Pipeline (GitHub Actions)

The `.github/workflows/cicd.yml` file defines the automated pipeline triggered on pushes or pull requests to the main branch.

**Pipeline Stages:**

1.  **Checkout Code:** Checks out the repository code.
2.  **Set up Python:** Configures the Python environment.
3.  **Run Unit Tests:**
    * Installs Python dependencies (`requirements.txt`).
    * Executes FastAPI unit tests using `pytest`.
    * `pytest tests/`
4.  **SonarQube SAST Scan:**
    * Integrates with SonarQube (Cloud or self-hosted) to perform Static Application Security Testing.
    * Requires SonarQube server URL, token, and project key configured as GitHub Secrets.
    * *(Implementation details depend on SonarQube setup - typically involves running a SonarScanner command)*
5.  **Snyk SCA Scan:**
    * Scans project dependencies (`requirements.txt`) for known vulnerabilities using Snyk.
    * Requires `SNYK_TOKEN` configured as a GitHub Secret.
    * `snyk test --json > snyk_report.json`
    * Uploads `snyk_report.json` as a build artifact.
6.  **Build Docker Image:**
    * Builds the Docker image using a `Dockerfile` designed to run the application as a **non-root user**.
    * `docker build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .`
7.  **Trivy Image Scan:**
    * Scans the built Docker image for OS package and library vulnerabilities using Trivy.
    * `trivy image --format json -o trivy_report.json $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG`
    * Uploads `trivy_report.json` as a build artifact.
    * *(Optional: Fail the build based on severity threshold)*
8.  **Push Docker Image to ECR:**
    * Logs into AWS ECR using credentials configured via OIDC or access keys (Secrets).
    * Tags the Docker image.
    * `docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG`
9.  **Deploy to EC2 via SSM:**
    * Uses the AWS CLI (configured with credentials) to trigger an SSM Run Command on the target EC2 instance(s).
    * The SSM document (`AWS-RunShellScript` or a custom document) typically performs:
        * `docker pull $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG`
        * `docker stop <container_name> || true`
        * `docker rm <container_name> || true`
        * `docker run -d --name <container_name> -p 80:8000 $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG`
    * `aws ssm send-command --document-name "AWS-RunShellScript" --instance-ids $INSTANCE_ID --parameters '{"commands":["<deployment_script_commands>"]}' --region $AWS_REGION`
10. **ZAP DAST Scan:**
    * Starts the newly deployed application container.
    * Runs OWASP ZAP Baseline Scan (or Full Scan) against the application URL (using the `EC2_IP` secret) using the official ZAP Docker container.
    * `docker run --network host owasp/zap2docker-stable zap-baseline.py -t http://$EC2_IP:80 -J zap_report.json`
    * Uploads `zap_report.json` as a build artifact.
    * *(Requires the application URL to be accessible from the GitHub runner or a dedicated scanning environment)*

## 4. Infrastructure Cleanup (Terraform)

To avoid ongoing AWS charges, the infrastructure created by Terraform should be destroyed when no longer needed.

* Navigate to the `terraform/` directory.
* Run `terraform destroy`.
* Confirm the destruction by typing `yes`.

## Prerequisites

* AWS Account
* Terraform installed
* AWS CLI installed and configured (optional, primarily for local testing/setup)
* Docker installed
* GitHub Account
* SonarQube Instance (Cloud or Self-Hosted) - Optional, adapt pipeline if not used.
* Snyk Account and API Token
* OWASP ZAP (for local testing, pipeline uses Docker image)

## Setup

1.  **Clone Repository:** `git clone <repository_url>`

2.  **Configure AWS Credentials:**
    * Set up AWS credentials securely for Terraform and GitHub Actions.
    * **Recommended:** Use OIDC for GitHub Actions to authenticate with AWS without long-lived keys.
    * **Alternative:** If using IAM User access keys, store `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as GitHub Secrets. Ensure the IAM user or role has the necessary permissions (see below).

3.  **Configure Repository Secrets:**
    Navigate to your GitHub repository's `Settings` > `Secrets and variables` > `Actions` and add the following secrets:
    * `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`: Required if *not* using OIDC. The associated IAM user/role needs `AmazonEC2ContainerRegistryFullAccess` and `AmazonSSMFullAccess` policies (or more granular permissions).
    * `AWS_REGION`: The AWS region where resources are deployed (e.g., `us-east-1`).
    * `ECR_REGISTRY`: The URI of your ECR registry (e.g., `<account_id>.dkr.ecr.<region>.amazonaws.com`).
    * `ECR_REPOSITORY`: The name of your ECR repository.
    * `EC2_INSTANCE_ID`: The ID of the EC2 instance deployed by Terraform. Retrieve this from the `terraform output` after applying the configuration and add it as a secret.
    * `EC2_IP`: The Public IP address of the EC2 instance. Retrieve this from `terraform output` after applying and add it as a secret. Used for the ZAP scan target.
    * `SONAR_TOKEN`: Your SonarQube/SonarCloud access token for SAST scans.
    * `SONAR_HOST_URL`: The URL of your SonarQube/SonarCloud instance.
    * `SNYK_TOKEN`: Your Snyk API token for SCA scans.

4.  **Configure Terraform Variables:**
    * Update `terraform/variables.tf` or create a `terraform.tfvars` file with your specific settings (e.g., region, instance type, desired VPC CIDR, ECR repository name).

5.  **Initialize Terraform:**
    * Navigate to `terraform/`.
    * Run `terraform init`.

## Usage

1.  **Provision Infrastructure (First time):**
    * Navigate to `terraform/`.
    * Run `terraform plan` to review the changes.
    * Run `terraform apply` and confirm with `yes`.
    * **Important:** Note the `ec2_instance_id` and `ec2_public_ip` outputs. Update the `EC2_INSTANCE_ID` and `EC2_IP` GitHub repository secrets with these values.

2.  **Develop & Push:**
    * Make changes to the FastAPI application code (`main.py`, add tests in `test`).

3.  **Monitor Pipeline:**
    * Observe the GitHub Actions workflow execution in the "Actions" tab of your repository after pushing changes.

4.  **Review Reports:**
    * Check the generated `snyk_report.json`, `trivy_report.json`, and `zap_report.json` artifacts from the workflow run for security findings. Download them from the completed workflow run summary page.

5.  **Access Application:**
    * Once deployed, access your FastAPI application via the EC2 instance's public IP (e.g., `http://<EC2_IP>`).

6.  **Test CI/CD Pipeline:**
    * To manually trigger and test the full pipeline:
        * Make a minor, non-breaking change in the application code (e.g., update a version string or a comment in `main.py` or `test_main.py`).
        * Commit and push the change to the branch configured to trigger the workflow (e.g., `main`).
        ```bash
        # Example change made, now commit and push
        git add .
        git commit -m "Test: Trigger CI/CD pipeline"
        git push origin main
        ```
    * Monitor the pipeline execution in the GitHub Actions tab.

7.  **Destroy Infrastructure:**
    * When finished, navigate to the `terraform/` directory.
    * Run `terraform destroy` and confirm with `yes`.

