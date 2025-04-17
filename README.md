# 🚀 FastAPI Application with DevSecOps on AWS using GitHub Actions

This project demonstrates a secure CI/CD pipeline for a FastAPI application deployed on AWS EC2 using Terraform for infrastructure management and GitHub Actions for automation. The pipeline incorporates various security scanning tools (SAST, SCA, Image Scanning, DAST) following DevSecOps best practices.

## Overview

The goal of this project is to establish a robust and secure workflow for developing, testing, scanning, and deploying a FastAPI application.

* **Infrastructure as Code (IaC):** Terraform is used to define and manage AWS resources.
* **CI/CD Automation:** GitHub Actions orchestrates the entire process from code commit to deployment.
* **DevSecOps Integration:** Security checks are embedded throughout the pipeline:
    * **SAST:** SonarQube analyzes static code for vulnerabilities.
    * **SCA:** Snyk scans dependencies for known vulnerabilities.
    * **Image Scanning:** Trivy scans the Docker image for OS and library vulnerabilities.
    * **DAST:** OWASP ZAP scans the running application for runtime vulnerabilities.
* **Secure Deployment:** Deployment to EC2 is handled via AWS Systems Manager (SSM) Run Command, eliminating the need for SSH keys.
* **Secure Containerization:** The Docker image is built using a non-root user to minimize potential container security risks.

## 1. Infrastructure Provisioning (Terraform)

Terraform (within a `terraform` directory) is responsible for creating the necessary AWS infrastructure:

* **Networking:** VPC, Public Subnets, Internet Gateway, Route Tables.
* **Compute:** EC2 Instance with an appropriate IAM Role allowing SSM access and ECR pull permissions.
* **Container Registry:** Elastic Container Registry (ECR) repository to store the Docker image.
* **Security:** Security Groups to control traffic to the EC2 instance.
* **Storage:** S3 to store terraform remote backend state file.

**Deployment Strategy:**
Terraform create AWS resources and the primary deployment mechanism is handled by the GitHub Actions pipeline after the image is built and pushed.

## 2. EC2 Instance Setup

After the EC2 instance is created by Terraform, a `user_data` script name `ubuntu_provision.sh` is used to provision the instance with necessary software:

* **Docker Engine:** To run the containerized FastAPI application.
* **AWS CLI:** To interact with AWS services.

*Note:* Using SSM Agent (pre-installed on most recent AMIs) and Run Command for deployment is preferred over SSH-based provisioning for enhanced security. Ensure the EC2 instance's IAM role has the `AmazonSSMManagedInstanceCore` policy attached.

## 3. CI/CD Pipeline (GitHub Actions)

The `.github/workflows/main.yml` file defines the automated pipeline triggered on pushes requests to the main branch.

**Pipeline Stages**

1.  **Checkout Code** Checks out the repository code.

2.  **Set up Python** Configures the Python environment.

3.  **Run Unit Tests:**
    * Installs Python dependencies (`requirements.txt`).
    * Executes FastAPI unit tests using `pytest`.

4.  **SonarQube SAST Scan:**
    * Integrates with SonarQube (Cloud) to perform Static Application Security Testing.
    * Requires SonarQube token as a GitHub repository secrets.

5.  **Snyk SCA Scan:**
    * Scans project dependencies (`requirements.txt`) for known vulnerabilities using Snyk.
    * Requires `SNYK_TOKEN` configured as a GitHub repository secrets.
    * Uploads `snyk_report.json` as a build artifact.

6.  **Build Docker Image:**
    * Builds the Docker image using a `Dockerfile` designed to run the application as a **non-root user**.
    
7.  **Trivy Image Scan:**
    * Scans the built Docker image for OS package and library vulnerabilities using Trivy.
    * Uploads `trivy_report.json` as a build artifact.

8.  **Push Docker Image to ECR:**
    * Logs into AWS ECR using credentials configured via Access keys (Secrets).
    * Tags and push the Docker image to AWS ECR.

9.  **Deploy to EC2 via SSM:**
    * Stop and remove existing docker image.
    * Run new docker image.

10. **ZAP DAST Scan:**
    * Starts the newly deployed application container.
    * Runs OWASP ZAP Baseline Scan (or Full Scan) against the application URL using the official ZAP Docker container.
    * Uploads `zap_report.json` as a build artifact.
    * *(Requires the application URL to be accessible from the GitHub runner or a dedicated scanning environment)*

## Getting Started

Follow these steps to set up the infrastructure:

1.  **Provision Infrastructure**
    * Navigate to `terraform/`.
    * Run `terraform plan` to review the changes.
    * Run `terraform apply` and confirm with `yes`.
    * **Important:** Note the `EC2_INSTANCE_ID` and `EC2_IP`` outputs. Update the `EC2_INSTANCE_ID` and `EC2_IP` GitHub repository secrets with these values.
    
    ```bash
    cd terraform
    terraform init
    terraform plan
    terraform apply -auto-approve
    ```

2.  **Configure repository secrets**

    * `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`: The associated IAM user/role needs `AmazonEC2ContainerRegistryFullAccess` and `AmazonSSMFullAccess` policies

    * `EC2_INSTANCE_ID`: The ID of the EC2 for SSM service. Retrieve this from the `terraform output` after applying the configuration and add it as a secret.

    * `EC2_IP`: The Public IP address of the EC2 instance. Retrieve this from `terraform output` after applying and add it as a secret. Used for the ZAP scan target.

    * `SONAR_TOKEN`: SonarCloud access token for SAST scans.

    * `SNYK_TOKEN`: Snyk API token for SCA scans.

3.  **Test Github action CI/CD pipeline**

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

6.  **Test external access**

    Test FastApi with `curl` command.

    ```bash
    curl -v <EC2 public ip address>
    ```
10.  **Clean up**

    Destroy terraform infrastructure.

    ```bash
    cd terraform
    terraform destroy -auto-approve
    ```