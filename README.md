# AWS Security Hub Reviewer

This repository contains a Makefile that automates counting the number of AWS Security Hub findings that match a certain standard. It uses the AWS CLI, jq, and awsume.

## Prerequisites
To use this tool, you need to have the following installed:

- The AWS CLI
- `jq`
- `awsume`
- `make`

## Setup

To install the dependencies, run the following command:

```text
make install
```

This will install `jq`, `awscli`, and `awsume` if they are not already installed.

Next, configure awsume with the AWS account that you want to count findings for:

```text
awsume <profile>
```

Finally, configure the AWS CLI with the same AWS account:

```text
aws configure --profile <profile>
```

## Usage

To describe the number of total active controls and the critical or high-severity findings from AWS Foundational Security Best Practices standard, run the following command:

```text
make
```

This will execute the default Makefile target (`make run-logged`) which records the console output to a file named `output_<date_time>.txt`.

To run the process without the output being written to a file, run the following command:

```text
make run
```

You can also clean up the output files by running:

```text
make clean
```

This will remove all `output_*.txt` files from the current directory.

## Troubleshooting

If you encounter any issues with running the tool, try running the commands manually to see if you get any errors. If you are still having issues, consult the AWS CLI, `jq`, or `awsume` documentation for more information.
