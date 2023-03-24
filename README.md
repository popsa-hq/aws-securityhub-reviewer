# AWS Security Hub Findings Counter

This repository contains a Makefile that automates counting the number of AWS Security Hub findings that match a certain standard. It uses the AWS CLI, jq, and awsume.

## Prerequisites
To use this tool, you need to have the following installed:

- AWS CLI
- `jq`
- `awsume`
- `make`


## Setup

To install the dependencies, run the following command:

```text
make install
```

This will install jq, awscli, and awsume if they are not already installed.

Next, configure awsume with the AWS account that you want to count findings for:

```text
awsume <profile>
```

Finally, configure the AWS CLI with the same AWS account:

```text
aws configure --profile <profile>
```

## Usage

To count the number of findings that match the AWS Foundational Security Best Practices standard, run the following command:

```text
make run
```

This will output the number of matching findings to the console and to a file named output_<date_time>.txt.

You can also clean up the output files by running:

```text
make clean
```

This will remove all output_*.txt files from the current directory.

## Customization

If you want to count findings that match a different standard, update the awscli command in the run target of the Makefile.

## Troubleshooting

If you encounter any issues with running the tool, try running the commands manually to see if you get any errors. If you are still having issues, consult the AWS CLI, jq, or awsume documentation for more information.