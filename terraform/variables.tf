
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "instance_name" {
  type    = string
  default = "windows-ssh"
}

variable "instance_availability_zone" {
  type    = string
  default = "ap-northeast-1a"
}

variable "security_group_name" {
  type    = string
  default = "ssh_windows"
}

variable "ami_name_prefix" {
  type    = string
  default = "packer-windows-ssh"
}

variable "with_ssh_check" {
  type        = bool
  default     = true
  description = "If true, ssh connectivity check will run."
}

variable "admin_user_account" {
  type    = string
  default = "Administrator"
}

variable "normal_user_account" {
  type    = string
  default = "user_a"
}

variable "ssh_private_key_path_admin" {
  type    = string
  default = "../packer/ssh_private_key_win_admin_rsa.pem"
}

variable "ssh_private_key_path_normal_user" {
  type    = string
  default = "../packer/ssh_private_key_win_normal_rsa.pem"
}

variable "ssh_timeout" {
  type    = string
  default = "10m"
}

variable "aws_vpc_id" {
  type    = string
  default = ""
  validation {
    condition     = 0 < length(var.aws_vpc_id) && substr(var.aws_vpc_id, 0, 4) == "vpc-"
    error_message = "Variable aws_vpc_id must not be empty and start with vpc-*"
  }
}

variable "vpc_subnet_id" {
  type    = string
  default = ""
  validation {
    condition     = 0 < length(var.vpc_subnet_id) && substr(var.vpc_subnet_id, 0, 7) == "subnet-"
    error_message = "Variable vpc_subnet_id must not be empty and start with subnet-*"
  }
}

variable "ssh_private_key_path" {
  type    = string
  default = ""
  validation {
    condition     = 0 < length(var.ssh_private_key_path)
    error_message = "Variable ssh_private_key_path must not be empty."
  }
}
