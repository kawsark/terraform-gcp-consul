.DEFAULT_GOAL := plan

deploy: clean init plan apply

clean:
	rm *.pem
	terraform destroy --auto-approve
	rm -rf .terraform/

init: 
	terraform init

plan: init
	terraform plan

apply: init
	terraform apply --auto-approve

push_pem_to_kube:
	./scripts/push_pem_to_kube.sh

.PHONY: deploy clean init plan apply push_pem_to_kube