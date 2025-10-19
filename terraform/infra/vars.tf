variable "aws_region" {
    default = "us-west-2"
    description = "AWS region"
}

variable "environment" {
  default = "three-tier"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "CIDR block of the vpc"
}

variable "public_subnets_cidr" {
  type        = list(any)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
  description = "CIDR block for Public Subnet"
}

variable "private_subnets_cidr" {
  type        = list(any)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]
  description = "CIDR block for Private Subnet"
}

variable "db_subnets_cidr" {
  type        = list(any)
  default     = ["10.0.4.0/24", "10.0.5.0/24"]
  description = "CIDR block for Database Subnet"
}


variable "azs" {
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d", "us-west-2e", "us-west-2f"]
  description = "Availability Zones"
}
