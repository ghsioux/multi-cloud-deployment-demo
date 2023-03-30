# Azure infra setup

First, be sure to source the `env.sh` file created during the [environment setup](../env-setup/env-setup.md):

```bash
$ source env.sh
```
## Azure CLI setup

Use `az login` to login to Azure in the subscription you want to use:

```bash
$ az login
```

## Create a role that will be used by the service principal

We'll create a custom role with permissions to manage container group in the resource group we've created during the infra setup.

> ⚠️ **The role below is very permissive as it allows you to manage all container groups in the resource group. You should only use it for testing purposes. In a production environment, you should create a role that only grants the permissions that your deployment needs.**

```bash
$ az role definition create --role-definition @- <<EOF
{
  "Name": "Container Application Administrator",
  "Description": "Manage container application",
  "Actions": [
    "Microsoft.ContainerInstance/containerGroups/*"
  ],
  "AssignableScopes": [
    "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$AZURE_RESOURCE_GROUP"
  ]
}
EOF
```

## Create the service principal

We can now create an Azure service principal and assign it the role we've just created.

```bash
$ az ad sp create-for-rbac \
  -n $AZURE_SERVICE_PRINCIPAL_NAME \
  --role "Container Application Administrator" \
  --scopes /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$AZURE_RESOURCE_GROUP
```

## Create the federated credential

All what remains now is to create the federated credential that will be used by the `Azure/aci-deploy` action to authenticate to Azure with OIDC.

```bash
# Retrieve the application ID of the service principal we've just created
APPLICATION_ID=$(az ad app list --display-name $AZURE_SERVICE_PRINCIPAL_NAME --query [].appId -o tsv)

# Create the federated credential
$ az ad app federated-credential create --id $APPLICATION_ID --parameters @- <<EOF
{
  "audiences": [
    "api://AzureADTokenExchange"
  ],
  "description": "OIDC configuration for PetClinic deployment in Azure Container Instance",
  "issuer": "https://token.actions.githubusercontent.com",
  "name": "petclinic-oidc",
  "subject": "$AZURE_OIDC_IDENTITY"
}
EOF
```

## Prepare the GitHub environment secrets


We'll create three GitHub environment secrets in the environment `azure` that will contain the information related to the service principal created above. These secret will be used by the [Azure/login](../../.github/workflows/deploy-to-azure-aci.yml#L56-L61) action to authenticate to Azure using OIDC.

Let's first retrieve the values:
```bash
# change the subscription name to match the one you're using
$ AZURE_SUBSCRIPTION="Visual Studio Enterprise Subscription"

# retrieve the various infos we need
$ AZURE_CLIENT_ID=$(az ad app list --all --query "[?displayName=='$AZURE_SERVICE_PRINCIPAL_NAME'].appId" --output tsv)
$ AZURE_TENANT_ID=$(az account list --all --query "[?name=='$AZURE_SUBSCRIPTION'].tenantId" --output tsv)
$ AZURE_SUBSCRIPTION_ID=$(az account list --all --query "[?name=='$AZURE_SUBSCRIPTION'].id" --output tsv)

$ echo $AZURE_CLIENT_ID
$ echo $AZURE_TENANT_ID
$ echo $AZURE_SUBSCRIPTION_ID
```

Using the web UI, go to your repository, then to `Settings` > `Environments` > `azure` > `Secrets` and create the three secrets:
* a secret named `AZURE_CLIENT_ID` with the value of the `AZURE_CLIENT_ID` variable;
* a secret named `AZURE_TENANT_ID` with the value of the `AZURE_TENANT_ID` variable;
* a secret named `AZURE_SUBSCRIPTION_ID` with the value of the `AZURE_SUBSCRIPTION_ID` variable.

Alternatively, you can use the GitHub CLI to create the secret:
```
# Note: if you want to run the following command from your Codespace, 
# you'll have to reauthenticate first to get a GitHub token that will
# let you update environment secrets:
#
# $ unset GITHUB_TOKEN
# $ gh auth login
#
# this is not a very secure approach as a privileged GitHub token will
# exist in your Codespace.

# set the secret to the aws environment using the gh cli
$ gh secret set --env azure AZURE_CLIENT_ID -b "$AZURE_CLIENT_ID"
$ gh secret set --env azure AZURE_TENANT_ID -b "$AZURE_TENANT_ID"
$ gh secret set --env azure AZURE_SUBSCRIPTION_ID -b "$AZURE_SUBSCRIPTION_ID"
```