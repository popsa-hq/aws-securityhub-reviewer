SHELL:=/bin/bash
output_file := output_$(shell date +'%Y-%m-%d_%H-%M-%S').txt

.DEFAULT_GOAL := run

.PHONY: run

run:
	@echo "ℹ️  Setting up Output File: ${output_file}"
	touch $(output_file)

	@echo "ℹ️  Waiting for MFA token to be added" | tee -a $(output_file)
	awsume -a popsa-production --no-session || true | tee -a $(output_file)
	
	@echo "ℹ️  Checking enabled AWS Foundational Security Best Practices" | tee -a $(output_file)
	aws securityhub get-enabled-standards --no-cli-pager | tee -a $(output_file)
	
	@echo "ℹ️  Checking configured finding aggregator" | tee -a $(output_file)
	aggregator_arn=`aws securityhub list-finding-aggregators | jq -r '.FindingAggregators[0].FindingAggregatorArn'` && \
	aws securityhub get-finding-aggregator --finding-aggregator-arn $$aggregator_arn --no-cli-pager | tee -a $(output_file)
	
	@echo "ℹ️  Checking active findings count"
	aws securityhub get-findings --query 'Findings[?RecordState==`ACTIVE` && Compliance.AssociatedStandards[?StandardsId==`standards/aws-foundational-security-best-practices/v/1.0.0`]]' --output text | tee -a $(output_file) | wc -l

	@echo "ℹ️  Checking for active critical severity findings"
	aws securityhub get-findings --query 'Findings[?Severity.Label==`CRITICAL`] | [?RecordState==`ACTIVE`] | [*][Title, GeneratorId]' --filters '{"GeneratorId":[{"Value": "aws-foundational-security","Comparison":"PREFIX"}]}' --no-cli-pager | tee -a $(output_file)
		
install:
	@echo "ℹ️  Installing dependencies..."
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
	# Configure awsume alias
	awsume-configure --shell zsh
	@echo "ℹ️  Installation complete. You may need to configure AWSCLI and awsume before use."

clean:
	@echo "ℹ️  Cleaning output files..."
	find . -type f -regex "./output[0-9]*\.txt" -delete

