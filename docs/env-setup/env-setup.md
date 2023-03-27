# Environment setup

Before we start the [infra setup](./infra-setup/) and [OIDC setup](./oidc-setup/), we need to setup consistent environment variables for the cloud providers:

For AWS:
| Environment Variable | Description |
| --- | --- | 
| AWS_REGION | The AWS region where we'll deploy the container app |
| AWS_ECS_CLUSTER_NAME | The name of the ECS cluster we'll create to host the container app |
| AWS_ECS_SERVICE_NAME | The name of the ECS service |
| AWS_IAM_ROLE | IAM role name |
| AWS_OIDC_TOCKEN_SUB |

For Azure:
| Environment Variable | Description |
| --- | --- | 
| AZURE_REGION | Azure region |
| AZURE_RESOURCE_GROUP | Azure resource group name |
| AZURE_SERVICE_PRINCIPAL_NAME | Azure service principal name |
| AZURE_OIDC_TOCKEN_SUB |

For GCP:
| Environment Variable | Description |
| --- | --- | 
| GCP_PROJECT_ID | GCP project ID |
| GCP_REGION | GCP region |
| GCP_SERVICE_ACCOUNT | GCP service account name |
| GCP_WORKLOAD_IDENTITY_POOL | GCP workload identity pool name |
| GCP_WORKLOAD_IDENTITY_PROVIDER | GCP workload identity provider name |

Below is the environment file - named `env.sh` - we'll use for the demo setup, feel free to adapt the values to your needs:

```bash
#!/bin/bash

# AWS
export AWS_REGION="ap-southeast-1"
export AWS_ECS_CLUSTER_NAME="demo-ecs-cluster"
export AWS_ECS_SERVICE_NAME="spring-petclinic"
export AWS_IAM_ROLE="GitHub-Actions-Spring-PetClinic"
export AWS_OIDC_TOCKEN_SUB="repo:ghsioux-octodemo/spring-petclinic:environment:aws"

# Azure
export AZURE_REGION="eastus"
export AZURE_RESOURCE_GROUP="rg-spring-petclinic"
export AZURE_SERVICE_PRINCIPAL_NAME="spring-petclinic"
export AZURE_OIDC_TOCKEN_SUB="repo:ghsioux-octodemo/spring-petclinic:environment:azure"

# GCP
export GCP_PROJECT_ID="spring-petclinic-123456"
export GCP_REGION="europe-west1"
export GCP_SERVICE_ACCOUNT="github-actions-petclinic-sa"
export GCP_WORKLOAD_IDENTITY_POOL="gh-petclinic-pool"
export GCP_WORKLOAD_IDENTITY_PROVIDER="gh-petclinic-provider"
```

