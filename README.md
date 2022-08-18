# packer_aws_windows_ssh
Example configurations for creating ssh opened Windows Server on AWS EC2 using Packer.  
There are also Terraform configurations to create an actual instance from the AMI that is made by Packer and helper commands with Makefile.  
This instance will consist of
- having Administrator account and normal user account(by default name "user_a"), see [here](#about-userdata)
- SSH server running, but SSH password authentication will be disabled. see [here](#about-userdata)

It checked to run the instance by specified below AMI name filter.
- Windows_Server-2019-English-Full-Base-*
- Windows_Server-2022-English-Full-Base-*

# Usage
To make AMI through Packer.
"SUBNET_ID" and "ADMIN_PASSWORD" must be specified based on your environment.
```
cd packer;\
packer init .;\
export PACKER_CACHE_DIR=".";\
export SUBNET_ID="****";\
export ADMIN_PASSWORD="****";\
packer build .
```
There is also another helper command as Make targets, see [here](#Helper-Makefile)  

# Requirements(Tools)
Packer  
Terraform (if run helper commands)  
make (if run helper commands)  

# Packer Information
The main contents to state this repo.  

## Requirements
| Name | Version |
|------|---------|
| packer | >= 1.7.3 |

## Plugins
| Name | Version |
|------|---------|
| [amazon](https://github.com/hashicorp/packer-plugin-amazon/tree/main/docs) | >= 1.0.0 |
| [sshkey](https://www.packer.io/plugins/datasources/sshkey) | >= 1.0.1 |

## Input Variables
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_subnet_id | AWS VPC Subnet ID to run source instance | `string` | `"env("SUBNET_ID")"` | yes |
| admin_password | Account password for "Administrator"  | `string` | `"env("ADMIN_PASSWORD")"` | yes |
| region | AMI will be made in the region | `string` | `"ap-northeast-1"` | no |
| ami_name_prefix | AMI name prefix, this prefix will combine timestamp string then set as a AMI name and tag:Name(example: "packer-windows-ssh-20220801010203") | `string` | `"packer-windows-ssh"` | no |
| instance_type | source instance launch on this instance type | `string` | `"t2.micro"` | no |
| userdata_template_path | This file will use as a userdata for setting up the instance, see [here](#about-userdata)  | `string` | `"./userdata.tpl"` | no |
| ssh_timeout | ssh timeout seconds | `string` | `"10m"` | no |
| source_ami_name_prefix | This string used as a name filter prefix for finding source AMI image(example :"Windows_Server-2019-English-Full-Base-*") | `string` | `"Windows_Server-2019-English-Full-Base-"` | no |
| admin_user_account | Administrator user account name the instance has | `string` | `"Administrator"` | no |
| normal_user_account | Nomal user account, it will make through userdata,see [here](#about-userdata) | `string` | `"user_a"` | no |

## About Userdata
By default, userdata.tpl file will be used to create userdata for setting up the source instance.  
In the userdata, 
- [Install OpenSSH through "Add-WindowsCapability"](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=powershell) 
- [Setup SSH Server (set Administrator and normal user public key to authorized_keys, change permission, disable Password authentication)](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement)
- Create Normal User and its USER_PROFILE through calling Win32 API userenv CreateProfile, [The link helped me a lot.](https://gist.github.com/crshnbrn66/7e81bf20408c05ddb2b4fdf4498477d8)

Some key information(Normal user name, admin public key, user public key) wiil be replaced by Packer builtin function (templatefile)[https://www.packer.io/docs/templates/hcl_templates/functions/file/templatefile]
```actual configuration
~~~
user_data = templatefile(var.userdata_template_path,
    {
        admin_key = data.sshkey.admin_key.public_key,
        user_name = var.normal_user_account,
        user_key  = data.sshkey.normal_user_key.public_key
    }
)
~~~
```

# Terraform information
Optional contents.  
Terraform configuration will be used to make an actual instance for debugging and confirming.  
This configuration is combined with [Makefile](#Helper-Makefile) targets.

## Requirements
| Name | Version |
|------|---------|
| terraform | >= 0.13.1 |

## Providers
| Name | Version |
|------|---------|
| aws | >= 4.20.0 |

## Modules
| Name | Version |
|------|---------|
| [module.ec2_instance](https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/latest) | ~> 3.0 |

## Data
| Name | Description | 
|------|-------------|
| [data.tls_public_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/public_key) | extracted public key from Input variable file [ssh_private_key_path](#ssh-private-key-path)|
| [data.aws_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | Source AMI instance to create ec2 instance |

## Resources
| Name | Description | 
|------|-------------|
| [aws_security_group.windows_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | the security group will attach to the instance, open SSH(22) inbound traffic from 0.0.0.0/0 and no outbound traffic limitations |
| [aws_key_pair.instance_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | will be registered as an instance's SSH key pair see [Input Variables also](#ssh-private-key-path)|
| [null_resource.check_ssh_connectivity_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | to check SSH connectivity for Administrator, triggered  by changing instance_id, if "var.with_ssh_check" is false then it'll be ignored. |
| [null_resource.check_ssh_connectivity_normal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | to check SSH connectivity for Normal user, triggered  by changing instance_id, if "var.with_ssh_check" is false then it'll be ignored. |

## Input Variables
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_vpc_id | AWS VPC ID to run instance | `string` | `""` | yes |
| vpc_subnet_id | AWS VPC Subnet ID to run instance | `string` | `""` | yes |
| <a name="ssh-private-key-path"></a> ssh_private_key_path | The Key will be used to extract its public key, and set as an instance key name of "key-${var.instance_name}" | `string` | `""` | yes |
| instance_type | EC2 Instance run on the instance type  | `string` | `"t2.micro"` | no |
| instance_name | EC2 Instance Name, It will set as an instance name and tag:Name  | `string` | `"windows-ssh"` | no |
| instance_availability_zone | AZ to run the instance  | `string` | `"ap-northeast-1a"` | no |
| security_group_name | It will be set as an "aws_security_group.windows_ssh" name, the security group will attach to the instance, open SSH(22) inbound traffic from 0.0.0.0/0 and no outbound traffic limitations | `string` | `"ssh_windows"` | no |
| ami_name_prefix | AMI filter rule name prefix to find the AMI Image that was built by Packer. The filter rule is name:"${ami_name_prefix}*"  | `string` | `"packer-windows-ssh"` | no |
| with_ssh_check | If true, ssh connectivity check will run  | `bool` | `true` | no |
| admin_user_account | Administrator user account name the instance has  | `string` | `"Administrator"` | no |
| normal_user_account | Normal user account, it will make through userdata through Packer, see [here](#about-userdata) | `string` | `"user_a"` | no |
| ssh_private_key_path_admin | SSH private key file path for Administrator user account | `string` | `"../packer/ssh_private_key_win_admin_rsa.pem"` | no |
| ssh_private_key_path_normal_user | SSH private key file path for Normal user account | `string` | `"../packer/ssh_private_key_win_normal_rsa.pem"` | no |

## Outputs
| Name | Description |
|------|-------------|
| public_ip | The instance public ip |

# Helper Makefile
The Makefile provides helper commands for creating AMI through Packer, running the instance to use Terraform, etc.
## prerequisite
**Before running make targets, edit the .env file for specifying your VPC_ID and SUBNET_ID.**

## ``` make ami ```
Make AMI Image in the packer directory.
### By default
- SUBNET_ID that is specified in .env will pass as a variable "subnet_id" on "packer build" command. 
- requires input "admin_password" that will set as a User "Administrator"'s password. 
- ssh keys that are made by Packer "sshkey" plugin will be put in the same directory(./packer), the path specified as "PACKER_CACHE_DIR", see [here](https://www.packer.io/plugins/datasources/sshkey). 

## ``` make ec2 ```
make AWS EC2 instance in the terraform directory.
### By default
- variable "aws_vpc_id" and "vpc_subnet_id" will pass based on the .env file. 
- variable "ssh_private_key_path" will pass based on ADMIN_KEY variable in Makefile. 

## ``` make clean ```
run "terraform destroy"

## ``` make all ```
run targets "ami" "ec2" "clean".