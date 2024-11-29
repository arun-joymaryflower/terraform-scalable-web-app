# terraform-scalable-web-app
Terraform project to deploy a scalable and highly available web application on AWS. Includes infrastructure automation for EC2 instances, auto-scaling groups, load balancer, and RDS database, fully documented for portfolio showcase.

 Static Website Deployment Using Terraform on AWS
Overview
This project exemplifies the deployment of a highly available, scalable static website using AWS and Terraform for Infrastructure as Code (IaC). It integrates essential cloud engineering concepts such as:

Automating AWS resource provisioning.
Secure network design with a VPC and subnets.
Load balancing for high availability.
Static content hosting on EC2 instances.
Objective: Showcase proficiency in Terraform and AWS, with a focus on hands-on problem-solving for a cloud support engineer role.

Key Highlights

Infrastructure-as-Code Excellence
Written entirely in Terraform, enabling version-controlled, automated, and repeatable infrastructure provisioning.
Best Practices
Modularized Terraform configuration for scalability.
Proper use of variables for flexibility across environments.
Outputs to retrieve critical information easily.
Cloud Expertise Demonstrated
Understanding of AWS services such as VPC, EC2, ALB, IAM, and Auto Scaling Groups.
Configured a secure and optimized infrastructure for web hosting.
Architecture
This project deploys a cloud architecture following AWS best practices:


VPC with Public Subnets:
A dedicated VPC with two public subnets across different Availability Zones for high availability.
Internet Gateway and Route Tables for secure connectivity.
EC2 Instance Hosting Static Website:

Deployed an EC2 instance with NGINX pre-configured to serve static content.
Configured Security Groups for controlled inbound and outbound traffic.

Application Load Balancer (ALB):
Distributes incoming traffic across multiple EC2 instances for reliability and scalability.
Provides a single point of access with DNS name resolution.

Scalability and Modularity:
The infrastructure is designed to easily incorporate additional features like auto-scaling, HTTPS, and monitoring with minimal changes.

Setup and Deployment
Follow these steps to replicate the project:

1. Prerequisites
Terraform installed on your system.
AWS CLI configured with an IAM user having sufficient permissions.
An SSH key pair uploaded to AWS.
2. Clone the Repository
bash
Copy code
git clone https://github.com/arun-joymaryflower/terraform-scalable-web-app
cd terraform-scalable-web-app
3. Initialize Terraform
bash
Copy code
terraform init
4. Review the Plan
bash
Copy code
terraform plan
5. Apply Configuration
bash
Copy code
terraform apply
6. Test the Static Website
Access the static website using the DNS name of the Application Load Balancer.
Key Files
File	Purpose
main.tf	Core configuration for AWS resources (VPC, EC2, ALB).
variables.tf	Parameterized variables for flexibility.
outputs.tf	Outputs critical information such as ALB DNS name.
provider.tf	Configures Terraform to use AWS as the provider.
architecture-diagram.png	Visual representation of the infrastructure setup.
terraform-output.png	Screenshot showing successful Terraform execution.

Why This Project?
This project was specifically designed to demonstrate:

Proficiency with Terraform for automating cloud infrastructure.
Practical experience in AWS, showcasing the ability to design and implement secure, scalable, and cost-effective solutions.
Problem-solving skills, with attention to detail in debugging and testing configurations.
Future Enhancements
Add SSL/TLS certificates for secure HTTPS communication.
Implement auto-scaling groups for better scalability.
Replace EC2 instances with AWS S3 and CloudFront for optimized static website hosting.
License
