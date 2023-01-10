###############################
########### Common ############
###############################

variable "common_tags" {
  type        = map(string)
  description = "Tags for VPC resources"
  default     = {}
}

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "eu-west-3"
}

variable "azs" {
  description = "availability zones to use in AWS region"
  type        = list(string)
  default = [
    "eu-west-3a",
    "eu-west-3b",
    "eu-west-3c",
  ]
}

variable "tags" {
  type        = map(string)
  description = "Tags for VPC resources"
  default     = {}
}

variable "resource_name_prefix" {
  description = "Prefix for resource names in VPC infrastructure"
  default     = "mp"
}


###############################
############# VPC #############
###############################

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}



variable "allowed_inbound_cidrs_lb" {
  type        = list(string)
  description = "(Optional) List of CIDR blocks to permit inbound traffic from to load balancer"
  default     = null
}

variable "allowed_inbound_cidrs_ssh" {
  type        = list(string)
  description = "(Optional) List of CIDR blocks to permit for SSH to Vault nodes"
  default     = null
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type"
}

variable "key_name" {
  type        = string
  default     = null
  description = "(Optional) key pair to use for SSH access to instance"
}

variable "kms_key_deletion_window" {
  type        = number
  default     = 7
  description = "Duration in days after which the key is deleted after destruction of the resource (must be between 7 and 30 days)."
}

variable "leader_tls_servername" {
  type        = string
  description = "One of the shared DNS SAN used to create the certs use for mTLS"
  default     = "vault.demo.internal"
}

variable "lb_health_check_path" {
  type        = string
  description = "The endpoint to check for Vault's health status."
  default     = "/v1/sys/health?activecode=200&standbycode=200&sealedcode=200&uninitcode=200"
}

variable "lb_type" {
  description = "The type of load balancer to provision; network or application."
  type        = string
  default     = "application"

  validation {
    condition     = contains(["application", "network"], var.lb_type)
    error_message = "The variable lb_type must be one of: application, network."
  }
}

variable "node_count" {
  type        = number
  default     = 3
  description = "Number of Vault nodes to deploy in ASG"
}

variable "private_subnet_tags" {
  type        = map(string)
  description = "Tags which specify the subnets to deploy Vault into"
  default = {
    subnet = "private"
  }
}

variable "ssl_policy" {
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
  description = "SSL policy to use on LB listener"
}

variable "user_supplied_ami_id" {
  type        = string
  description = "(Optional) User-provided AMI ID to use with Vault instances. If you provide this value, please ensure it will work with the default userdata script (assumes latest version of Ubuntu LTS). Otherwise, please provide your own userdata script using the user_supplied_userdata_path variable."
  default     = null
}

variable "user_supplied_iam_role_name" {
  type        = string
  description = "(Optional) User-provided IAM role name. This will be used for the instance profile provided to the AWS launch configuration. The minimum permissions must match the defaults generated by the IAM submodule for cloud auto-join and auto-unseal."
  default     = null
}

variable "user_supplied_kms_key_arn" {
  type        = string
  description = "(Optional) User-provided KMS key ARN. Providing this will disable the KMS submodule from generating a KMS key used for Vault auto-unseal"
  default     = null
}

variable "user_supplied_userdata_path" {
  type        = string
  description = "(Optional) File path to custom userdata script being supplied by the user"
  default     = null
}

variable "vault_version" {
  type        = string
  default     = "1.8.2"
  description = "Vault version"
}

variable "public_ssh_port" {
  default = "22"
}

variable "ipv4_cidr_block" {}
