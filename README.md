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

## AWS Services Used

## Network Design

## Security Design

## Application Architecture

## High Availability and Auto Scaling

## Database Architecture

## Monitoring and Alerting

## Automated EC2 Bootstrapping

## Testing and Validation

## Challenges and Troubleshooting

## Key Takeaways
