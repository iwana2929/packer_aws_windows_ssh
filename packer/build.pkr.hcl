packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/amazon"
    }

    sshkey = {
      version = ">= 1.0.1"
      source  = "github.com/ivoronin/sshkey"
    }
  }
}

variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "ami_name_prefix" {
  type    = string
  default = "packer-windows-ssh"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "vpc_subnet_id" {
  type = string
  validation {
    condition     = 7 < length(var.vpc_subnet_id) && substr(var.vpc_subnet_id, 0, 7) == "subnet-"
    error_message = <<EOF
    Variable vpc_subnet_id must be specified a valid Subnet id, starting with \"subnet-\"..
EOF
  }
}

variable "userdata_template_path" {
  type    = string
  default = "./userdata.tpl"
}

variable "ssh_timeout" {
  type    = string
  default = "10m"
}

variable "source_ami_name_prefix" {
  type    = string
  default = "Windows_Server-2019-English-Full-Base-"
}

variable "admin_user_account" {
  type    = string
  default = "Administrator"
}

variable "normal_user_account" {
  type    = string
  default = "user_a"
}

variable "admin_password" {
  type    = string
  default = env("PACKER_VAR_admin_password")
  validation {
    condition     = 0 < length(var.admin_password)
    error_message = <<EOF
    Variable admin_password must be specified as env:PACKER_VAR_admin_password.
EOF
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  ami_name  = "${var.ami_name_prefix}-${local.timestamp}"
}

data "sshkey" "admin_key" {
  name = "win_admin"
  type = "rsa"
}

data "sshkey" "normal_user_key" {
  name = "win_normal"
  type = "rsa"
}

source "amazon-ebs" "windows_ssh" {
  ami_name                    = local.ami_name
  communicator                = "ssh"
  instance_type               = var.instance_type
  region                      = var.region
  subnet_id                   = var.vpc_subnet_id
  associate_public_ip_address = true
  source_ami_filter {
    filters = {
      name                = "${var.source_ami_name_prefix}*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  user_data = templatefile(var.userdata_template_path,
    {
      admin_key = data.sshkey.admin_key.public_key,
      user_name = var.normal_user_account,
      user_key  = data.sshkey.normal_user_key.public_key
    }
  )
  ssh_username         = var.admin_user_account
  ssh_private_key_file = data.sshkey.admin_key.private_key_path
  ssh_timeout          = var.ssh_timeout
  tags = {
    Name = "${local.ami_name}"
  }
}

build {
  name    = "windows_ssh_setup"
  sources = ["source.amazon-ebs.windows_ssh"]
  provisioner "powershell" {
    inline = [
      "net user Administrator '${var.admin_password}'"
    ]
  }
}
