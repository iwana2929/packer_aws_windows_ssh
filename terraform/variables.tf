
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "instance_name" {
  type    = string
  default = "windows_ssh"
}

variable "ssh_key_pair_name" {
  type = string
  validation {
    condition     = 0 < length(var.ssh_key_pair_name)
    error_message = "Variable ssh_key_pair_name must not be empty."
  }
}

variable "aws_subnet_id" {
  type = string
  validation {
    condition     = 0 < length(var.aws_subnet_id) && substr(var.aws_subnet_id, 0, 7) == "subnet-"
    error_message = "Variable aws_subnet_id must not be empty and start with subnet-*"
  }
}

variable "aws_vpc_id" {
  type = string
  validation {
    condition     = 0 < length(var.aws_vpc_id) && substr(var.aws_vpc_id, 0, 4) == "vpc-"
    error_message = "Variable aws_vpc_id must not be empty and start with vpc-*"
  }
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
