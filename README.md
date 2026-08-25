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

Security groups are used to restrict communication between each tier of the architecture following a least privilege approach.

The Application Load Balancer security group allows inbound HTTP traffic on port 80 from the public internet. The ALB acts as the public entry point for the application, while its listener and target group route requests to healthy application instances.

The EC2 application security group allows inbound HTTP traffic on port 80 only from the ALB security group. This prevents the application instances from directly accepting HTTP traffic from the public internet while still allowing the ALB to communicate with them.

The RDS security group allows inbound PostgreSQL traffic on port 5432 only from the EC2 application security group. This restricts database connectivity to the application tier rather than exposing the database directly to external clients.

Database credentials are stored in AWS Secrets Manager rather than being hardcoded into the application or User Data. EC2 instances use an IAM role with permission to retrieve the required secret at runtime, allowing the Flask application to authenticate to PostgreSQL without storing long-lived credentials directly in the application configuration.
## Application Architecture

Incoming HTTP requests first reach the internet facing Application Load Balancer, which forwards traffic to healthy EC2 instances in the Auto Scaling Group.

Each EC2 instance runs Nginx on port 80. Nginx acts as a reverse proxy, forwarding incoming requests to the Flask application running locally on port 8080.

The Flask application contains the application logic. When the root route (`/`) is requested, the application uses the AWS SDK for Python (`boto3`) to retrieve the database credentials from AWS Secrets Manager. The EC2 instance authenticates to AWS using its attached IAM role, so AWS credentials are stored on the instance.

After retrieving the database credentials, the Flask application uses a PostgreSQL client library to connect to the Amazon RDS PostgreSQL database over port 5432. The application runs a SQL query against the `users` table, retrieves the results, and generates an HTML response containing the database backed content.

The response then travels back through Nginx and the Application Load Balancer to the user.

### Request Flow

1. Client sends an HTTP request to the ALB.
2. The ALB forwards the request to a healthy EC2 target.
3. Nginx receives the request on port 80.
4. Nginx reverse proxies the request to Flask on `127.0.0.1:8080`.
5. Flask uses `boto3` and the EC2 IAM role to retrieve database credentials from Secrets Manager.
6. Flask connects to PostgreSQL on Amazon RDS over TCP port 5432.
7. PostgreSQL executes the requested SQL query and returns the data.
8. Flask generates the HTML response.
9. Nginx returns the response through the ALB to the client.
## High Availability and Auto Scaling

## Database Architecture

## Monitoring and Alerting

## Automated EC2 Bootstrapping

## Testing and Validation

## Challenges and Troubleshooting

## Key Takeaways
