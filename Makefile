.PHONY: ami ec2 clean all env-check
include .env

PWD = $(realpath $(dir $(firstword $(MAKEFILE_LIST))))
ADMIN_KEY = ${PWD}/packer/ssh_private_key_win_admin_rsa.pem
USER_KEY = ${PWD}/packer/ssh_private_key_win_normal_rsa.pem
WAIT_SECONDS = 120

ami: env-check
	@read -p "Enter admin_password:" ADMIN_PASSWORD;\
	cd packer;\
	export PACKER_CACHE_DIR=".";\
	export SUBNET_ID=${SUBNET_ID};\
	export ADMIN_PASSWORD=$${ADMIN_PASSWORD};\
	packer init .;\
	packer build .

ec2: env-check
	export TF_VAR_aws_vpc_id=${VPC_ID};\
	export TF_VAR_vpc_subnet_id=${SUBNET_ID};\
	export TF_VAR_ssh_private_key_path=${ADMIN_KEY};\
	cd terraform;\
	terraform init;\
	terraform apply;

clean: env-check
	export TF_VAR_aws_vpc_id=${VPC_ID};\
	export TF_VAR_vpc_subnet_id=${SUBNET_ID};\
	export TF_VAR_ssh_private_key_path=${ADMIN_KEY};\
	cd terraform;\
	terraform destroy;\

all: ami ec2 clean

env-check:
ifndef VPC_ID
	$(error VPC_ID must be specified)
endif
ifndef SUBNET_ID
	$(error SUBNET_ID must be specified)
endif

