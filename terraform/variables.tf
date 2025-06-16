variable "region" {
  description = "AWS region"
  default     = "ap-northeast-1"
}

variable "key_name" {
  description = "Existing EC2 Key Pair name"
  default     = "akash-ci-cd-key"
}

variable "cluster_name" {
  description = "EKS cluster name"
  default     = "akash-eks"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "Jenkins EC2 instance type"
  default     = "t2.medium"
}
