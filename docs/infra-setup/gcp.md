# GCP infra setup

First, be sure to source the `env.sh` file created during the [environment setup](../env-setup/env-setup.md):

```bash
$ source env.sh
```

You can adapt these values depending on your needs.

## GCP CLI setup

First login to GCP using the following command:

```bash
$ gcloud auth login --brief
```

If you don't have created any GCP project yet, you can create one using the following command:
```bash
$ gcloud projects create $GCP_PROJECT_ID

# Work in the newly created project
$ gcloud config set project $GCP_PROJECT_ID
```

## Enable the required services

We need to enable the APIs for Cloud Run and Artifact Registry:

```bash
# enable cloud run
$ gcloud services enable run.googleapis.com

# enable artifact registry
$ gcloud services enable artifactregistry.googleapis.com
```

## Create a GCP Artifact Registry

Since Cloud Run does not support GHCR, we need to create a GCP Artifact Registry to store our Docker images:

```bash
gcloud artifacts repositories create spring-petclinic \
    --repository-format=docker \
    --location=$GCP_REGION 
```