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

## Create a resource group
```bash
$ az group create -l $AZURE_REGION -n $AZURE_RESOURCE_GROUP
```

And.. that's it for Azure :) we do not need to create the container service in advance, as it will be done by the [`Azure/aci-deploy`](https://github.com/Azure/aci-deploy) action.