# ==========================================
# DEFINISI VARIABEL UTAMA (PARAMETER)
# ==========================================

variable "aws_region" {
  type        = string
  description = "Region AWS yang digunakan untuk AWS Learner Lab"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
  description = "Blok IP utama untuk VPC LKS"
  default     = "10.0.0.0/16"
}

variable "app_port" {
  type        = number
  description = "Port backend aplikasi Node.js atau Python"
  default     = 3000
}

variable "db_username" {
  type        = string
  description = "Username master untuk database RDS MySQL"
  default     = "adminlks"
}

variable "db_password" {
  type        = string
  description = "Password master untuk database RDS MySQL"
  default     = "PasswordLKS2026!"
  sensitive   = true # Menandakan data ini rahasia agar tidak muncul sembarangan di log terminal
} 