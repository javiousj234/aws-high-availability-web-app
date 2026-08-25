# aws-high-availability-web-app
Highly available AWS web application using ALB, Auto Scaling, EC2, RDS PostgreSQL, Secrets Manager, and CloudWatch.
## Project Overview

I designed and deployed a highly available three tier web application architecture on AWS within a custom VPC spanning two Availability Zones. The architecture separates public facing, application, and database resources across public and private subnets to improve security, availability, and fault tolerance.

An internet facing ALB distributes HTTP traffic to EC2 instances running in private application subnets. The application tier is managed by an ASG using a custom Launch Template. User Data automatically bootstraps new instances by installing Nginx and Python dependencies, deploying a Flask application, configuring systemd, and starting the required services.

The application connects to a PostgreSQL database hosted on Amazon RDS in dedicated private database subnets. Security groups restrict communication between tiers so that EC2 instances accept application traffic from the ALB security group, while RDS accepts PostgreSQL traffic only from the application tier's security group.

Public subnets use an Internet Gateway for internet connectivity, while private application subnets use a NAT Gateway for outbound internet access without directly exposing the EC2 instances to inbound internet traffic.

The architecture also uses load balancer health checks and Auto Scaling to detect and replace unhealthy application instances, providing automated recovery and maintaining application availability.

Database credentials are stored in AWS Secrets Manager rather than being hardcoded into the application or EC2 User Data. The Flask application uses the EC2 instance's IAM role to retrieve the required database credentials at runtime, allowing application instances to access RDS without storing long-lived credentials in the application configuration.

Amazon CloudWatch provides monitoring for the environment, with alarms configured for unhealthy application targets and high CPU utilization across key resources. Amazon SNS delivers notifications when alarm conditions are reached. This complements the architecture's automated recovery mechanisms by providing visibility into infrastructure and application health even when the ASG is able to replace unhealthy instances automatically.
## Architecture
![AWS Architecture Diagram](three-tier-architecture-diagram.png)
## AWS Services Used
| Service | Purpose |
|---|---|
| Amazon VPC | Provides the isolated network environment for the architecture |
| Amazon EC2 | Hosts the Nginx web server and Flask application |
| Application Load Balancer  | Distributes incoming HTTP traffic across healthy EC2 instances |
| EC2 Auto Scaling | Maintains application capacity and replaces unhealthy instances |
| Launch Templates | Defines the configuration used to launch EC2 instances |
| Amazon RDS for PostgreSQL | Provides the managed relational database for the application |
| AWS Secrets Manager | Stores database credentials securely for runtime retrieval |
| AWS IAM | Allows EC2 instances to retrieve database credentials without hardcoded AWS credentials |
| NAT Gateway | Provides outbound internet access for EC2 instances in private subnets |
| Internet Gateway | Provides internet connectivity for resources in public subnets |
| Amazon CloudWatch | Monitors infrastructure health and resource utilization |
| Amazon SNS | Sends notifications when CloudWatch alarms enter an alarm state |
## Network Design

The architecture is deployed within a custom VPC using the `10.0.0.0/16` CIDR range. I selected a /16 network to provide sufficient address space for the current architecture while leaving room to create additional subnets and resources as the environment grows.

The VPC is divided into public, private application, and private database subnets across two Availability Zones. The public subnets contain internet facing resources such as the Application Load Balancer and NAT Gateway, while EC2 application instances are deployed within private subnets to prevent direct exposure to the public internet.

Public subnet route tables contain a default route (`0.0.0.0/0`) to the Internet Gateway. Private application subnet route tables instead direct outbound internet traffic (`0.0.0.0/0`) to the NAT Gateway. This allows private EC2 instances to initiate outbound connections, such as downloading software packages, without requiring direct inbound internet connectivity.

Resources are distributed across two Availability Zones to improve availability and fault tolerance. If an application instance or Availability Zone becomes unavailable, the Application Load Balancer can continue directing traffic to healthy application instances in the remaining Availability Zone while the Auto Scaling Group maintains the desired application capacity.
## Security Design

## Application Architecture

## High Availability and Auto Scaling

## Database Architecture

## Monitoring and Alerting

## Automated EC2 Bootstrapping

## Testing and Validation

## Challenges and Troubleshooting

## Key Takeaways
