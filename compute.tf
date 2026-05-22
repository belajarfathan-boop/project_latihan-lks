# ==========================================
# 1. SECURITY GROUPS (FIREWALL BERLAPIS)
# ==========================================

# Security Group untuk Load Balancer (Bisa diakses publik)
resource "aws_security_group" "alb_sg" {
  name        = "lks-alb-sg"
  description = "Allow HTTP public traffic"
  vpc_id      = aws_vpc.lks_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "LKS-ALB-SG" }
}

# Security Group untuk Server EC2 (Sesuai nama ec2_sg di file lo)
resource "aws_security_group" "ec2_sg" { 
  name        = "lks-ec2-sg"
  description = "Allow traffic from ALB only"
  vpc_id      = aws_vpc.lks_vpc.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # SSH dibuka ke publik agar bisa dideploy via GitHub Actions
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "LKS-EC2-SG" }
}

# ==========================================
# 2. APPLICATION LOAD BALANCER (ALB)
# ==========================================

resource "aws_lb" "lks_alb" {
  name               = "lks-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = { Name = "LKS-Web-ALB" }
}

resource "aws_lb_target_group" "lks_tg" {
  name     = "lks-app-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.lks_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "3000"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lks_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lks_tg.arn
  }
}

# ==========================================
# 3. LAUNCH TEMPLATE & AUTO SCALING
# ==========================================

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-minimal-*-x86_64"]
  }
} 

resource "aws_launch_template" "lks_lt" {
  name_prefix   = "lks-template-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  # BERUBAH: Ditaruh di subnet publik (associate true) agar dapet IP Publik buat SSH GitHub
  network_interfaces {
    associate_public_ip_address = true 
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo dnf update -y
              sudo dnf install -y ruby wget
              curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
              sudo dnf install -y nodejs
              cd /home/ec2-user
              wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install
              chmod +x ./install
              sudo ./install auto
              sudo systemctl start codedeploy-agent
              EOF
  )

  iam_instance_profile {
    name = "LabInstanceProfile"
  }

  tags = { Name = "LKS-Launch-Template" }
}

resource "aws_autoscaling_group" "lks_asg" {
  desired_capacity    = 2 
  max_size            = 4 
  min_size            = 1 
  target_group_arns   = [aws_lb_target_group.lks_tg.arn]
  
  # BERUBAH: Pindah ke public_1 dan public_2 agar bisa dapet IP Publik & internetan langsung
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  launch_template {
    id      = aws_launch_template.lks_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "LKS-App-Server"
    propagate_at_launch = true
  }
} 

# ==========================================
# 4. AWS CODEDEPLOY (TAMBAHAN BARU)
# ==========================================

# Membuat Aplikasi CodeDeploy
resource "aws_codedeploy_app" "lks_codedeploy" {
  compute_platform = "Server"
  name             = "lks-codedeploy"
}

# Membuat Deployment Group untuk Auto Scaling Group
resource "aws_codedeploy_deployment_group" "lks_dg" {
  app_name              = aws_codedeploy_app.lks_codedeploy.name
  deployment_group_name = "lks-deployment-group"
  
  # Menggunakan default LabRole dari AWS Academy Learner Lab
  service_role_arn      = "arn:aws:iam::464253666565:role/LabRole" 

  deployment_config_name = "CodeDeployDefault.OneAtATime"

  # Menyambungkan CodeDeploy langsung ke Auto Scaling Group di atas
  autoscaling_groups = [aws_autoscaling_group.lks_asg.name] 

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }
} 