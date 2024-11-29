# Define the provider for AWS
provider "aws" {
  region = "ap-south-1"  # Set to your desired AWS region
}

# Create the VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "TerraformVPC"
  }
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1a"  # Specify the AZ
  tags = {
    Name = "Public_Subnet"
  }
}

# Create a second public subnet for load balancing (multiple AZs)
resource "aws_subnet" "public_az2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"  # Different availability zone
  map_public_ip_on_launch = true
  tags = {
    Name = "Public_Subnet_2"
  }
}

# Create an Internet Gateway for the VPC to connect to the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Main IGW"
  }
}

# Create a Route Table for the public subnets to route traffic to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "Public Route Table"
  }
}

# Associate the route table with the subnets
resource "aws_route_table_association" "public_az1" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

# Create a security group for the web application
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  # Allow SSH access (port 22) for debugging (only from your IP for security)
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["192.168.0.0/24"]  # Replace with your machine's IP address
  }

  # Allow HTTP access (port 80)
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP traffic from anywhere
  }

  # Allow access to Node.js app on port 8080
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow access to Node.js app from anywhere
  }


  # Allow all outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebSecurityGroup"
  }
}

# Create the EC2 instance for the web application
resource "aws_instance" "web_app" {
  ami = "ami-0614680123427b75e"  # Amazon Linux 2023 AMI
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Add user_data to install and configure Apache on instance boot
      user_data = <<-EOF
              #!/bin/bash
              # Update and install Apache HTTP Server
              sudo yum update -y
              sudo yum install -y httpd

              # Create a simple static HTML page
              echo '<html><body><h1>Hello, World from Terraform!</h1></body></html>' | sudo tee /var/www/html/index.html

              # Start the Apache server
              sudo systemctl start httpd
              sudo systemctl enable httpd
              EOF

  tags = {
    Name = "Terraform_web_app"
    Environment = "Development"
  }
}

# Create an Application Load Balancer (ALB)
resource "aws_lb" "web_lb" {
  name               = "web-alb"
  internal           = false  # Public ALB
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_az2.id]

  tags = {
    Name = "Web-Application-Load-Balancer"
  }
}

# Create the target group for the load balancer to route traffic to
resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "Web-Target-Group"
  }
}

# Create the listener for the load balancer to accept HTTP traffic
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Attach the EC2 instance to the target group
resource "aws_lb_target_group_attachment" "web_attachment" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_app.id
  port             = 80
}

resource "aws_launch_template" "web_launch_template" {
  name_prefix   = "web-launch-template-"
  image_id      = "ami-0614680123427b75e"  # Use a valid AMI ID for your environment and region
  instance_type = "t2.micro"               # Adjust instance type if needed
  key_name      = "web app"                # Your key pair name for SSH access

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.public.id
    security_groups             = [aws_security_group.web_sg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Hello, World!" > /var/www/html/index.html
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
  EOF
  )

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 8  # Size in GB
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }

  tags = {
    Name = "WebInstance"
  }
}


# Create autoscaling group
resource "aws_autoscaling_group" "web_asg" {
  desired_capacity     = 2  # Adjust as needed
  max_size             = 5
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.public.id]  # Reference the subnet where instances will be launched

  launch_template {
    id = aws_launch_template.web_launch_template.id
    version              = "$Latest"
}
  target_group_arns = [aws_lb_target_group.web_tg.arn]

  health_check_type        = "ELB"
  #health_check_grace_period = 300
  #load_balancers           = [aws_lb.web_lb.id]
}

# Add autoscaling group to target group
resource "aws_lb_target_group_attachment" "asg_attachment" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_app.id
  port             = 80
}

# Setup Cloudwatch Alarm to trigger scaling based on CPU Utilization
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "high_cpu_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "300"
  statistic = "Average"
  threshold = "80"
  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
  insufficient_data_actions = []
  dimensions = {
    AutoScalingGroupName =aws_autoscaling_group.web_asg.name
  }
}

# Create Scaling Policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name  = aws_autoscaling_group.web_asg.name
}


