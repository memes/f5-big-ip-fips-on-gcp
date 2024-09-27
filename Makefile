# This makefile implements wrappers around various kitchen test commands. The
# intent is to make it easy to execute a full test suite, or individual actions,
# with a safety net that ensures the test harness is present before executing
# kitchen commands. Specifically, Terraform in test/setup has been applied, and
# the examples have been cloned to an emphemeral folder and source modified to
# use these local files.
#
# Many kitchen commands have an equivalent target; kitchen action [pattern] becomes
# make action[.pattern]
#
# E.g.
#   kitchen test                 =>   make test
#   kitchen verify example-gsr   =>   make verify.example-gsr
#   kitchen converge pr          =>   make converge.pr
#   kitchen destroy              =>   make destroy
#
TF_COMMAND := tofu
RUBYOPT := W0
ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
HARNESS_JSON := $(ROOT_DIR)/test/setup/harness.json

# Default target will create necessary test harness, then launch kitchen test.
.DEFAULT: test
.PHONY: test.%
test.%: $(HARNESS_JSON)
	cd $(ROOT_DIR) && RUBYOPT=$(RUBYOPT) bundle exec kitchen test $*

.PHONY: test
test: $(HARNESS_JSON)
	cd $(ROOT_DIR) && RUBYOPT=$(RUBYOPT) bundle exec kitchen test

.PHONY: destroy.%
destroy.%: $(HARNESS_JSON)
	cd $(ROOT_DIR) && RUBYOPT=$(RUBYOPT) bundle exec kitchen destroy $*

.PHONY: destroy
destroy: $(HARNESS_JSON)
	cd $(ROOT_DIR) && RUBYOPT=$(RUBYOPT) bundle exec kitchen destroy

.PHONY: verify.%
verify.%: $(HARNESS_JSON)
	cd $(ROOT_DIR) && RUBYOPT=$(RUBYOPT) bundle exec kitchen verify $*

.PHONY: verify
verify: $(HARNESS_JSON)
	cd $(ROOT_DIR) && RUBYOPT=$(RUBYOPT) bundle exec kitchen verify

.PHONY: converge.%
converge.%: $(HARNESS_JSON)
	cd $(ROOT_DIR) && RUBYOPT=$(RUBYOPT) bundle exec kitchen converge $*

.PHONY: converge
converge: $(HARNESS_JSON)
	cd $(ROOT_DIR) && RUBYOPT=$(RUBYOPT) bundle exec kitchen converge

.PHONY: list.%
list.%: $(HARNESS_JSON)
	cd $(ROOT_DIR) && RUBYOPT=$(RUBYOPT) bundle exec kitchen list $*

.PHONY: list
list: $(HARNESS_JSON)
	cd $(ROOT_DIR) && RUBYOPT=$(RUBYOPT) bundle exec kitchen list

$(HARNESS_JSON): $(wildcard $(ROOT_DIR)/test/setup/*.tf) $(wildcard $(ROOT_DIR)/test/setup/*.auto.tfvars) $(wildcard $(ROOT_DIR)/test/setup/terraform.tfvars)
	$(TF_COMMAND) -chdir=$(ROOT_DIR)/test/setup init -input=false
	$(TF_COMMAND) -chdir=$(ROOT_DIR)/test/setup apply -input=false -auto-approve -target random_pet.prefix
	$(TF_COMMAND) -chdir=$(ROOT_DIR)/test/setup apply -input=false -auto-approve

.PHONY: clean
clean: $(wildcard $(HARNESS_JSON))
	-if test -n "$<" && test -f "$<"; then cd $(ROOT_DIR) && RUBYOPT=$(RUBYOPT) bundle exec kitchen destroy; fi
	if test -n "$<" && test -f "$<"; then $(TF_COMMAND) -chdir=$(<D) destroy -auto-approve; fi

.PHONY: realclean
realclean: clean
	find $(ROOT_DIR)/test/reports -depth 1 -type d -exec rm -rf {} +
	find $(ROOT_DIR) -type d -name .terraform -exec rm -rf {} +
	find $(ROOT_DIR) -type d -name terraform.tfstate.d -exec rm -rf {} +
	find $(ROOT_DIR) -type f -name .terraform.lock.hcl -exec rm -f {} +
	find $(ROOT_DIR) -type f -name terraform.tfstate -exec rm -f {} +
	find $(ROOT_DIR) -type f -name terraform.tfstate.backup -exec rm -f {} +
	rm -rf $(ROOT_DIR)/.kitchen

# Helper to ensure code is ready for release
# 1. Tag is a valid semver with v prefix (e.g. v1.0.0)
# 2. Inspec controls have version matching the tag
# 3. Git tree is clean
.PHONY: pre-release.%
pre-release.%:
	@echo '$*' | grep -Eq '^v(?:[0-9]+\.){2}[0-9]+$$' || \
		(echo "Tag doesn't meet requirements"; exit 1)
	@grep -Eq '^version:[ \t]*$(subst .,\.,$(*:v%=%))[ \t]*$$' $(ROOT_DIR)/test/integration/fips/inspec.yml || \
		(echo "$(ROOT_DIR)/test/integration/fips/inspec.yml has incorrect tag"; exit 1)
	@test "$(shell cd $(ROOT_DIR) && git status --porcelain | wc -l | grep -Eo '[0-9]+')" == "0" || \
		(echo "Git tree is unclean"; exit 1)
	@echo 'Source is ready for release $*'
