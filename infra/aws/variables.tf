variable "project" {
  description = "Project name for tagging."
  type        = string
  default     = "qxli"
}

variable "product_name" {
  description = "Product name used in resource naming (prefix)."
  type        = string
  default     = "qxli"
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID where the instance will be launched."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID (public subnet with auto-assign public IP)."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (t2.micro is free-tier eligible)."
  type        = string
  default     = "t2.large"
}

variable "ami_id" {
  description = "AMI ID for the instance. Default is Ubuntu 22.04 LTS in us-east-1."
  type        = string
  default     = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS us-east-1
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB (free tier allows up to 30GB)."
  type        = number
  default     = 100
}

variable "key_pair_name" {
  description = "Base name for the AWS key pair created for SSH access (will be prefixed automatically)."
  type        = string
  default     = "qxli-gpu-key"
}

variable "ssh_public_key_path" {
  description = "Path to your public SSH key (e.g., ~/.ssh/id_rsa.pub)."
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks allowed to HTTP (80)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_https_cidrs" {
  description = "CIDR blocks allowed to HTTPS (443)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_app_ports" {
  description = "Additional app ports to open (e.g., QXLI UI, Ollama, n8n, Langflow)."
  type        = list(number)
  default     = [8888, 11434, 5678, 7860]
}
