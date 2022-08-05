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
  key_name                    = var.ssh_key_pair_name
  monitoring                  = false
  vpc_security_group_ids      = [aws_security_group.windows_ssh.id]
  subnet_id                   = var.aws_subnet_id
  availability_zone           = var.instance_availability_zone
  associate_public_ip_address = true
  tags = {
    Name = var.instance_name
  }
}

output "public_ip" {
  value = module.ec2_instance.public_ip
}
