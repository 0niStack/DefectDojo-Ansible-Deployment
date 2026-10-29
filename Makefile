INV ?= inventory/hosts.ini

.PHONY: deps ping check deploy update uninstall creds

deps:      ## Install required Ansible collections
	ansible-galaxy collection install -r requirements.yml

ping:      ## Test connectivity
	ansible -i $(INV) defectdojo -m ping

check:     ## Syntax check
	ansible-playbook -i $(INV) site.yml --syntax-check

deploy:    ## Install Docker + deploy DefectDojo
	ansible-playbook -i $(INV) site.yml

update:    ## Re-run: pulls code + images and restarts (TAG=x.y.z to set image tag)
	ansible-playbook -i $(INV) site.yml $(if $(TAG),-e defectdojo_image_tag=$(TAG),)

uninstall: ## Remove the stack (prompts about volumes)
	ansible-playbook -i $(INV) uninstall.yml

creds:     ## Show saved credentials
	@cat credentials/*.txt
