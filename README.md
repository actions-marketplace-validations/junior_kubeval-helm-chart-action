# *kubeval-helm-chart* Action

A GitHub Action to validate Helm charts extracted Kubernetes configuration files, using the [Kubeval](https://github.com/instrumenta/kubeval) CLI tool.

## Usage

### Pre-requisites

1. A GitHub repo containing a directory with your Helm charts (eg: `/charts`)
1. A workflow YAML file in your `.github/workflows` directory. An [example workflow](#example-workflow) is available below.
  For more information, reference the GitHub Help Documentation for [Creating a workflow file](https://help.github.com/en/articles/configuring-a-workflow#creating-a-workflow-file)
  
### Inputs

### Example Workflow

Create a workflow (eg: `.github/workflows/kubeval-helm-chart.yaml`):
