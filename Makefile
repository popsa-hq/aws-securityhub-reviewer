.DEFAULT_GOAL := run

.PHONY: run

run:
	
	@echo "ℹ️  Waiting for MFA token to be added"
	awsume -a popsa-production --no-session || true
	
	@echo "ℹ️  Checking enabled AWS Foundational Security Best Practices"
	aws securityhub get-enabled-standards --no-cli-pager
	
	@echo "ℹ️  Checking configured finding aggregator"
	aggregator_arn=`aws securityhub list-finding-aggregators | jq -r '.FindingAggregators[0].FindingAggregatorArn'` && \
	aws securityhub get-finding-aggregator --finding-aggregator-arn $$aggregator_arn --no-cli-pager
	
	@echo "ℹ️  Checking active findings count"
	aws securityhub get-findings --query 'Findings[?RecordState==`ACTIVE`]' --filters '{\"GeneratorId\":[{\"Value\": \"aws-foundational-security\",\"Comparison\":\"PREFIX\"}]}' --output text --no-cli-pager | wc -l
	
	@echo "ℹ️  Checking for active critical severity findings"
	aws securityhub get-findings --query 'Findings[?Severity.Label==`CRITICAL`] | [?RecordState==`ACTIVE`] | [*][Title, GeneratorId]' --filters '{"GeneratorId":[{"Value": "aws-foundational-security","Comparison":"PREFIX"}]}' --no-cli-pager
		
install:
	@echo "Installing dependencies..."
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
	@echo "Installation complete. You may need to configure AWSCLI and awsume before use."
