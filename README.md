# 🚀 FastAPI Application with DevSecOps on AWS using GitHub Actions

This project demonstrates a secure CI/CD pipeline for a FastAPI application deployed on AWS EC2 using Terraform for infrastructure management and GitHub Actions for automation. The pipeline incorporates various security scanning tools (SAST, SCA, Image Scanning, DAST) following DevSecOps best practices.

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

Terraform (within a `terraform/` directory) is responsible for creating the necessary AWS infrastructure:

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
* **AWS CLI:** To interact with AWS services if needed (though SSM reduces direct CLI dependency for deployment).

*Note:* Using SSM Agent (pre-installed on most recent AMIs) and Run Command for deployment is preferred over SSH-based provisioning for enhanced security. Ensure the EC2 instance's IAM role has the `AmazonSSMManagedInstanceCore` policy attached.

## 3. CI/CD Pipeline (GitHub Actions)

The `.github/workflows/main.yml` file defines the automated pipeline triggered on pushes or pull requests to the main branch.

**Pipeline Stages:**

1.  **Checkout Code:** Checks out the repository code.

2.  **Set up Python:** Configures the Python environment.

3.  **Run Unit Tests:**
    * Installs Python dependencies (`requirements.txt`).
    * Executes FastAPI unit tests using `pytest`.
    * `pytest tests/`

4.  **SonarQube SAST Scan:**
    * Integrates with SonarQube (Cloud) to perform Static Application Security Testing.
    * Requires SonarQube token, and project key configured as GitHub Secrets.

5.  **Snyk SCA Scan:**
    * Scans project dependencies (`requirements.txt`) for known vulnerabilities using Snyk.
    * Requires `SNYK_TOKEN` configured as a GitHub Secret.
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
    * Uses the AWS CLI (configured with credentials) to trigger an SSM Run Command on the target EC2 instance(s).
    * Stop and remove existing docker image.
    * Run new docker image.

10. **ZAP DAST Scan:**
    * Starts the newly deployed application container.
    * Runs OWASP ZAP Baseline Scan (or Full Scan) against the application URL using the official ZAP Docker container.
    * Uploads `zap_report.json` as a build artifact.
    * *(Requires the application URL to be accessible from the GitHub runner or a dedicated scanning environment)*

## Getting Started

Follow these steps to set up the infrastructure:

1.  **Initialize Terraform**
    ```bash
    cd terraform
    terraform init
    ```

2.  **Plan Terraform Infrastructure**
    ```bash
    terraform plan
    ```
    Review the output carefully to understand the resources that will be created.

3.  **Apply Terraform Infrastructure**
    ```bash
    terraform apply -auto-approve
    ```
    This command will provision the necessary infrastructure on AWS Cloud Infrastructure.

4.  **Configure repository secrets**

    * `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` (AWS User account requires AmazonEC2ContainerRegistryFullAccess and AmazonSSMFullAccess policy)

    * `EC2_INSTANCE_ID` for SSM service (Retrieve from terraform output)

    * `EC2_IP` for ZAP DAST scan (Retrieve from terraform output)

    * `SONAR_TOKEN` for SonarCloud SAST scan

    * `SNYK_TOKEN` for SNYK SCA scan


5.  **Test Github action CI/CD pipeline**

    Run the setup script located in the `kubernetes/script` directory.
    ```bash
    git commit --allow-empty -m "Triggering remote action"
    
    ```

6.  **Verify kubernetes resource in webapp namespace**

    Ensure the application components (Deployments, Services, Pods) are running.
    ```bash
    kubectl get all -n webapp
    ```

7.  **Test external access via Nginx ingress**

    Retrieve the AWS Load Balancer hostname or IP.
    ```bash
    kubectl descripe ingress -n webapp
    ```
    Test routing with `curl` using the appropriate host headers. `host = web.example.com` (Route to nginx service port 80)
    ```bash
    curl -i --header "Host: web.example.com" http://<loadbalance name or ip address>
    ```

    Test routing with `curl` using the appropriate host headers. `host = dev.web.example.com` (Route to nginx service port 80)
    ```bash
    curl -i --header "Host: dev.web.example.com" http://<loadbalance name or ip address>
    ```
8.  **Access ArgoCD application**

    Retrieve the Argo CD admin password from kubernetes secrets.

    ```bash
    kubectl get secrets argocd-initial-admin-secret -o yaml -n argocd
    ```

    Decode the password.
    ```bash
    echo "<password before decode>" | base64 --decode
    ```

    Port-forward to access the Argo CD UI.
    ```bash
    kubectl port-forward svc/argocd-server -n argocd 8080:80
    ```
    Access Argo CD at http://localhost:8080 and login using the username `admin` and the `decoded password`.

9.  **Test ArgoCD application**

    Modify deployment.yaml to change the number of replicas from 1 to 2. Wait a few minutes or manually trigger a sync in the Argo CD UI. You should see the number of nginx pods in `service name nginx` increase accordingly.

10.  **Clean up**

    Delete kubernetes webapp namespace.

     ```bash
    kubectl delete ns webapp
    terraform init
    ```
    Destroy the Terraform-managed infrastructure.

    ```bash
    cd terraform
    terraform destroy -auto-approve
    ```