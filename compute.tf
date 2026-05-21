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

# Security Group untuk Server EC2 (Hanya menerima trafik dari ALB)
resource "aws_security_group" "ec2_sg" {
  name        = "lks-ec2-sg"
  description = "Allow traffic from ALB only"
  vpc_id      = aws_vpc.lks_vpc.id

  # Port aplikasi (misal Node.js port 3000)
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Mengunci agar cuma ALB yang bisa masuk
  }

  # Mengizinkan EC2 download package/update ke luar internet via NAT Gateway
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
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id] # Catatan: Idealnya pakai 2 public subnet di AZ berbeda

  tags = { Name = "LKS-Web-ALB" }
}

# Target Group (Tempat mengarahkan trafik dari ALB ke EC2)
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

# Listener ALB (Mendengarkan request masuk di port 80)
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

# Mencari data AMI Amazon Linux 2023 terbaru secara otomatis
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-minimal-*-x86_64"] # Menggunakan versi minimal yang selalu ada di region lab
  }
} 

# Launch Template (Cetak biru / spesifikasi server EC2)
resource "aws_launch_template" "lks_lt" {
  name_prefix   = "lks-template-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro" # Tipe instance hemat biaya standar lab

  network_interfaces {
    associate_public_ip_address = false # Server ditaruh di private subnet, jadi ga butuh IP Publik langsung
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  # Skrip otomatisasi (User Data) untuk install Node.js & Agen CodeDeploy saat server menyala
  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo dnf update -y
              sudo dnf install -y ruby wget
              # Install Node.js 22 sesuai kisi-kisi
              curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
              sudo dnf install -y nodejs
              # Install CodeDeploy Agent
              cd /home/ec2-user
              wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install
              chmod +x ./install
              sudo ./install auto
              sudo systemctl start codedeploy-agent
              EOF
  )

  # Menggunakan IAM Role bawaan AWS Learner Lab agar EC2 punya izin akses
  iam_instance_profile {
    name = "LabInstanceProfile"
  }

  tags = { Name = "LKS-Launch-Template" }
}

# Auto Scaling Group (Mengatur jumlah server otomatis)
resource "aws_autoscaling_group" "lks_asg" {
  desired_capacity    = 2 # Jumlah server ideal yang dinyalakan di awal
  max_size            = 4 # Maksimal server kalau trafik melonjak
  min_size            = 1 # Minimal server tersisa
  target_group_arns   = [aws_lb_target_group.lks_tg.arn]
  vpc_zone_identifier = [aws_subnet.private_1.id] # Server dibuat di dalam Private Subnet

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