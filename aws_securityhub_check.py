#!/usr/bin/env python3
import subprocess
import datetime
import json
import time
import sys

import boto3
from botocore.config import Config

# AWS config with retry settings
boto_config = Config(
    retries={
        'max_attempts': 5,
        'mode': 'adaptive'
    }
)

client = boto3.client('securityhub', config=boto_config)

# Output file setup
timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
output_filename = f"output_{timestamp}.txt"

def log(msg):
    print(msg)
    with open(output_filename, "a") as f:
        f.write(msg + "\n")

def run_cmd(cmd):
    """Run shell command and log output."""
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True, text=True)
    log(result.stdout.strip())
    if result.stderr:
        log("⚠️ " + result.stderr.strip())
    return result.stdout.strip()

def check_enabled_standards():
    log("ℹ️  Checking enabled AWS Foundational Security Best Practices")
    run_cmd("aws securityhub get-enabled-standards --no-cli-pager")

def check_finding_aggregator():
    log("ℹ️  Checking configured finding aggregator")
    arn_cmd = "aws securityhub list-finding-aggregators | jq -r '.FindingAggregators[0].FindingAggregatorArn'"
    aggregator_arn = run_cmd(arn_cmd)
    run_cmd(f"aws securityhub get-finding-aggregator --finding-aggregator-arn {aggregator_arn} --no-cli-pager")

def count_active_issues():
    log("ℹ️  Counting total number of active issues")
    filters = {
        "RecordState": [{"Value": "ACTIVE", "Comparison": "EQUALS"}],
        "WorkflowStatus": [{"Value": "NEW", "Comparison": "EQUALS"}]
    }

    paginator = client.get_paginator("get_findings")
    page_iterator = paginator.paginate(
        Filters=filters,
        PaginationConfig={"PageSize": 100}
    )

    total = 0
    for i, page in enumerate(page_iterator):
        findings = page["Findings"]
        # Filter in Python for the correct standard
        filtered_findings = [
            f for f in findings
            if any(
                s.get("StandardsId") == "standards/aws-foundational-security-best-practices/v/1.0.0"
                for s in f.get("Compliance", {}).get("AssociatedStandards", [])
            )
        ]
        count = len(filtered_findings)
        total += count
        log(f"⏳ Page {i+1}: {count} findings (running total: {total})")
        time.sleep(0.1)  # simulate progress

    log(f"✅ Total ACTIVE issues: {total}")

def list_critical_high_findings():
    log("ℹ️  Listing all active findings of critical and high severity")
    filters = {
        "RecordState": [{"Value": "ACTIVE", "Comparison": "EQUALS"}],
        "WorkflowStatus": [{"Value": "NEW", "Comparison": "EQUALS"}],
        "SeverityLabel": [
            {"Value": "CRITICAL", "Comparison": "EQUALS"},
            {"Value": "HIGH", "Comparison": "EQUALS"}
        ]
    }

    paginator = client.get_paginator("get_findings")
    page_iterator = paginator.paginate(
        Filters=filters,
        PaginationConfig={"PageSize": 50}
    )

    total = 0
    for i, page in enumerate(page_iterator, 1):
        findings = page.get("Findings", [])
        # Filter in Python for the correct standard
        filtered_findings = [
            f for f in findings
            if any(
                s.get("StandardsId") == "standards/aws-foundational-security-best-practices/v/1.0.0"
                for s in f.get("Compliance", {}).get("AssociatedStandards", [])
            )
        ]
        for finding in filtered_findings:
            finding_id = finding.get("Id", "")
            title = finding.get("Title", "")
            description = finding.get("Description", "").replace("\n", " ").strip()
            severity = finding.get("Severity", {}).get("Label", "")
            status = finding.get("Workflow", {}).get("Status", "")
            account_id = finding.get("AwsAccountId", "")
            created_at = finding.get("CreatedAt", "")
            last_observed = finding.get("LastObservedAt", "")
            product_arn = finding.get("ProductArn", "")
            resource = finding.get("Resources", [{}])[0].get("Id", "")

            log("-------------------------------------------------------------------")
            log(f"🔐 [{severity}] {title}")
            log(f"🆔  {finding_id}")
            log(f"📦  Product ARN: {product_arn}")
            log(f"👤  Account ID:  {account_id}")
            log(f"📅  Created At:  {created_at}")
            log(f"📍  Last Seen:   {last_observed}")
            log(f"📄  Status:      {status}")
            log(f"📝  Description: {description}")
            log("-------------------------------------------------------------------\n")
            total += 1

        log(f"⏳ Finished page {i} of critical/high findings")

    log(f"✅ Total HIGH/CRITICAL findings: {total}")

def main():
    log(f"ℹ️  Setting up Output File: {output_filename}")
    with open(output_filename, "w") as f:
        f.write(output_filename + "\n")

    check_enabled_standards()
    check_finding_aggregator()
    count_active_issues()
    list_critical_high_findings()
    log("✅ Process complete")

if __name__ == "__main__":
    main()
