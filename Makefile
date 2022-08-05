.PHONY: ami ec2 test-ssh clean 

ADMIN_KEY = ./packer/ssh_private_key_win_admin_rsa.pem
USER_KEY = ./packer/ssh_private_key_win_normal_rsa.pem
TMP_ADMIN_KEY = /tmp/ssh_private_key_win_admin_rsa.pem
TMP_USER_KEY = /tmp/ssh_private_key_win_normal_rsa.pem

ami:
	@read -p "Enter vpc_subnet_id:" SUBNET_ID;\
	cd packer;\
	export PACKER_CACHE_DIR=".";\
	packer init .;\
	packer build  -var "vpc_subnet_id=$$SUBNET_ID" . 

ec2:
	cd terraform;\
	terraform init;\
	terraform apply;

test-ssh:
	cd terraform;\
	IP=`terraform output -raw public_ip`;\
	cd ..;\
	cp $(ADMIN_KEY) $(TMP_ADMIN_KEY) && chmod 400 $(TMP_ADMIN_KEY);\
	cp $(USER_KEY) $(TMP_USER_KEY) && chmod 400 $(TMP_USER_KEY);\
	ssh -i $(TMP_ADMIN_KEY) Administrator@$$IP echo "connected using ssh Administrator";\
	ssh -i $(TMP_USER_KEY) user_a@$$IP echo "connected using ssh Normal user";\
	rm -f $(TMP_ADMIN_KEY) $(TMP_USER_KEY);

clean:
	cd terraform;\
	terraform destroy;\
	rm -f $(TMP_ADMIN_KEY) $(TMP_USER_KEY);\
	rm -f $(ADMIN_KEY) $(USER_KEY);\
