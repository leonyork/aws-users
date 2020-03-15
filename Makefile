##########################
# Versions
##########################
AWSCLI_VERSION=1.17.13-alpine3.11.3
COMMIT_LINT_VERSION=8.3.5
ROTATE_KEYS_IMAGE_NAME=rotate-keys

##########################
# Variables
##########################
export REGION=us-east-1
REPO=leonyork/aws-linux-instance
STACK_NAME=ci-linux-instance-user

##########################
# Commands
##########################
AWS_CLI=docker run --rm \
	-e "AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID)" \
	-e "AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY)" \
	-v $(CURDIR):/app \
	-w /app \
	leonyork/awscli:$(AWSCLI_VERSION)

ROTATE_KEYS=docker run --rm \
	-e "AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID)" \
	-e "AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY)" \
	$(ROTATE_KEYS_IMAGE_NAME)

TRAVIS=docker-compose run travis
TRAVIS_ARGS=--com

COMMIT_LINT_DOCKER_IMAGE=gtramontina/commitlint:$(COMMIT_LINT_VERSION) 
COMMIT_LINT_VARS=--edit
COMMIT_LINT=docker run --rm -v $(CURDIR)/.git:/app/.git -v $(CURDIR)/commitlint.config.js:/app/commitlint.config.js -w /app $(COMMIT_LINT_DOCKER_IMAGE) $(COMMIT_LINT_VARS)

DEPLOY_USERS_CMD=$(AWS_CLI) cloudformation deploy \
		--template-file users.yml \
		--stack-name $(STACK_NAME) \
		--no-fail-on-empty-changeset \
		--capabilities CAPABILITY_IAM \
		--region $(REGION)

DELETE_USERS_CMD=$(AWS_CLI) cloudformation delete-stack \
		--stack-name $(STACK_NAME) \
		--region $(REGION)

USERNAME_CMD=$(AWS_CLI) cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--output text \
		--query "Stacks[0].Outputs[?OutputKey=='Username'].OutputValue"

##########################
# External targets
##########################

.PHONY: deploy-users
deploy-users:
	@$(DEPLOY_USERS_CMD)

.PHONY: delete-users
delete-users:
	@$(DELETE_USERS_CMD)

.PHONY: rotate-access-keys
rotate-access-keys: rotate-keys-build
	@docker-compose run --entrypoint sh travis travis.sh '$(shell $(ROTATE_KEYS) $(shell $(USERNAME_CMD)))' $(REPO)

##########################
# Dev targets
##########################

# Lint the commits that have been made to ensure they are conventional commits
.PHONY: commit-lint
commit-lint:
	docker pull --quiet $(COMMIT_LINT_DOCKER_IMAGE)
	$(COMMIT_LINT)

.PHONY: travis-login
travis-login:
	$(TRAVIS) login $(TRAVIS_ARGS)

.PHONY: travis-login-auto
travis-login-auto:
	@$(TRAVIS) login $(TRAVIS_ARGS) --auto --no-manual --github-token $(GITHUB_TOKEN)

.PHONY: travis-sh
travis-sh:
	docker-compose run --entrypoint sh travis

.PHONY: travis-env-list
travis-env-list:
	$(TRAVIS) env $(TRAVIS_ARGS) --no-interactive --repo $(REPO) list 

.PHONY: travis-restart
travis-restart:
	$(TRAVIS) restart $(TRAVIS_ARGS) --no-interactive --repo $(REPO)

.PHONY: log-oldest-access-key
log-oldest-access-key:
	@$(ACCESS_KEY_OLDEST_CMD)

##########################
# Internal targets
##########################
.PHONY: rotate-keys-build
rotate-keys-build:
	docker build -t $(ROTATE_KEYS_IMAGE_NAME) -f rotate-keys.Dockerfile --quiet .