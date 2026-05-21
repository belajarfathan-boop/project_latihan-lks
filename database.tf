# ==========================================
# 1. SECURITY GROUP UNTUK DATABASE & CACHE
# ==========================================

resource "aws_security_group" "db_sg" {
  name        = "lks-database-sg"
  description = "Allow traffic to RDS and ElastiCache from EC2"
  vpc_id      = aws_vpc.lks_vpc.id

  # Port MySQL (3306) - Hanya boleh diakses oleh Security Group milik EC2
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  # Port Redis (6379) - Hanya boleh diakses oleh Security Group milik EC2
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "LKS-DB-SG" }
}

# ==========================================
# 2. AMAZON RDS (MYSQL DATABASE)
# ==========================================

# Mengelompokkan Private Subnet 1 & 2 sebagai tempat bernaung DB Multi-AZ
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "lks-rds-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = { Name = "LKS-RDS-Subnet-Group" }
}

resource "aws_db_instance" "lks_rds" {
  allocated_storage      = 20
  max_allocated_storage  = 50
  db_name                = "lks_db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro" # Ukuran hemat biaya yang didukung Lab
  username               = "adminlks"
  password               = "PasswordLKS2026!" # Di produksi nyata, pakai Secret Manager. Untuk latihan/lab, ini standar tercepat.
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true

  tags = { Name = "LKS-RDS-MySQL" }
}

# ==========================================
# 3. AMAZON ELASTICACHE (REDIS)
# ==========================================

# Mengelompokkan Subnet untuk Redis
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "lks-redis-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

resource "aws_elasticache_cluster" "lks_redis" {
  cluster_id           = "lks-redis-cluster"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids   = [aws_security_group.db_sg.id]

  tags = { Name = "LKS-Redis-Cache" }
}
