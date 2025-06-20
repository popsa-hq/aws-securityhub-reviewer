SHELL:=/bin/bash
output_file := output_$(shell date +'%Y-%m-%d_%H-%M-%S').txt

.DEFAULT_GOAL := run-logged

.PHONY: run run-logged install clean

run-logged:
	@echo "ℹ️  Setting up Output File: ${output_file}"
	touch $(output_file)
	@echo "$(output_file)" > $(output_file)
	$(MAKE) run | tee -a $(output_file)

run:	
	@echo "ℹ️  Checking enabled AWS Foundational Security Best Practices"
	aws securityhub get-enabled-standards --no-cli-pager
	
	@echo "ℹ️  Checking configured finding aggregator"
	aggregator_arn=`aws securityhub list-finding-aggregators | jq -r '.FindingAggregators[0].FindingAggregatorArn'` && \
	aws securityhub get-finding-aggregator --finding-aggregator-arn $$aggregator_arn --no-cli-pager
	
	@echo "ℹ️  Counting total number of active issues"
	AWS_MAX_ATTEMPTS=5 \
	AWS_RETRY_MODE=adaptive \
	aws securityhub get-findings \
	--query 'Findings[?RecordState==`ACTIVE` && Workflow.Status==`NEW` && Compliance.AssociatedStandards[?StandardsId==`standards/aws-foundational-security-best-practices/v/1.0.0`]].{Id: Id}' \
	--output text \
	--no-cli-pager | wc -l

	@echo "ℹ️  Listing all active findings of critical and high severity"
	AWS_MAX_ATTEMPTS=5 \
	AWS_RETRY_MODE=adaptive \
	aws securityhub get-findings \
	--query 'Findings[?RecordState==`ACTIVE` && Workflow.Status==`NEW` && Compliance.AssociatedStandards[?StandardsId==`standards/aws-foundational-security-best-practices/v/1.0.0`] && (Severity.Label==`CRITICAL` || Severity.Label==`HIGH`)].{Id: Id, Title: Title, Severity: Severity.Label, WorkflowStatus: Workflow.Status, AwsAccountId: AwsAccountId, Description: Description, ProductArn: ProductArn, CreatedAt: CreatedAt, LastObservedAt: LastObservedAt}' \
	--output text \
	--no-cli-pager 

	@echo "✅ Process complete"

run-python:
	python3 aws_securityhub_check.py

install:
	@echo "ℹ️  Installing dependencies"
	# Install Homebrew if it's not already installed
	if ! command -v brew >/dev/null; then \
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"; \
	fi
	# Install awscli if it's not already installed
	if ! command -v aws >/dev/null; then \
		brew install awscli; \
	fi
	# Install jq if it's not already installed
	if ! command -v jq >/dev/null; then \
		brew install jq; \
	fi
	# Install awsume if it's not already installed
	if ! command -v awsume >/dev/null; then \
		pip install awsume; \
	fi
	# Install boto3 for python3
	if ! command -v boto3 >/dev/null; then \
		pip install boto3; \
	fi
	# Configure awsume alias
	awsume-configure --shell zsh
	@echo "ℹ️  Installation complete, you may need to configure AWSCLI and awsume before use"

clean:
	@echo "ℹ️  Cleaning output files..."
	find . -type f -name "output*.txt" -delete

