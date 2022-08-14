resource "aws_security_group" "windows_ssh" {
  vpc_id      = var.aws_vpc_id
  name        = var.security_group_name
  description = "Allow SSH Access"
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    self             = false
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = var.security_group_name
  }
}

data "tls_public_key" "ssh_public_key" {
  private_key_openssh = file("${var.ssh_private_key_path}")
}

resource "aws_key_pair" "instance_key" {
  key_name   = "key-${var.instance_name}"
  public_key = data.tls_public_key.ssh_public_key.public_key_openssh
}

data "aws_ami" "packer_ami" {
  filter {
    name   = "name"
    values = ["${var.ami_name_prefix}*"]
  }
  most_recent = true
  owners      = ["self"]
}

module "ec2_instance" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "~> 3.0"
  name                        = var.instance_name
  ami                         = data.aws_ami.packer_ami.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.instance_key.key_name
  monitoring                  = false
  vpc_security_group_ids      = [aws_security_group.windows_ssh.id]
  subnet_id                   = var.vpc_subnet_id
  availability_zone           = var.instance_availability_zone
  associate_public_ip_address = true
  tags = {
    Name = var.instance_name
  }
}

resource "null_resource" "check_ssh_connectivity_admin" {
  count = var.with_ssh_check ? 1 : 0
  triggers = {
    instance_id = module.ec2_instance.id
  }

  connection {
    type            = "ssh"
    host            = module.ec2_instance.public_ip
    user            = var.admin_user_account
    private_key     = file(var.ssh_private_key_path_admin)
    timeout         = var.ssh_timeout
    target_platform = "windows"
  }

  provisioner "remote-exec" {
    inline = [
      "echo connected using ssh ${var.admin_user_account}",
    ]
  }
}

resource "null_resource" "check_ssh_connectivity_normal" {
  count = var.with_ssh_check ? 1 : 0
  triggers = {
    instance_id = module.ec2_instance.id
  }

  connection {
    type            = "ssh"
    host            = module.ec2_instance.public_ip
    user            = var.normal_user_account
    private_key     = file(var.ssh_private_key_path_normal_user)
    timeout         = var.ssh_timeout
    target_platform = "windows"
  }

  provisioner "remote-exec" {
    inline = [
      "echo connected using ssh ${var.normal_user_account}",
    ]
  }
}

output "public_ip" {
  value = module.ec2_instance.public_ip
}
