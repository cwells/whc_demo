.ONESHELL:

TF=tflocal

venv/bin/activate:
	@python -m venv venv 

.terraform: venv/bin/activate
	@. venv/bin/activate
	@$(TF) init

deploy: .terraform
	@. venv/bin/activate
	@$(TF) apply

localstack/up: 
	@docker compose -f docker-compose-localstack.yaml up

localstack/down: 
	@docker compose -f docker-compose-localstack.yaml down

requirements: venv/bin/activate .terraform
	@. venv/bin/activate
	@python -m pip install -r requirements.txt

run: requirements
	@. venv/bin/activate
	@DEBUG=1 python app.py 

.PHONY: deploy run 
