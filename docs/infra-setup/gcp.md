# GCP infra setup

First, be sure to source the `env.sh` file created during the [environment setup](../env-setup/env-setup.md):

```bash
$ source env.sh
```

## GCP CLI setup

Login to GCP using the following command:

```bash
$ gcloud auth login --brief
```

If you don't have created any GCP project yet, you can create one using the following command:
```bash
$ gcloud projects create $GCP_PROJECT_ID

# Work in the newly created project
$ gcloud config set project $GCP_PROJECT_ID
```

## Set a billing account for the project

This is a manual step that you need to do in the GCP console. You can find more information [here](https://cloud.google.com/billing/docs/how-to/modify-project).

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
gcloud artifacts repositories create $GCP_ARTIFACT_REGISTRY \
    --repository-format=docker \
    --location=$GCP_REGION 
```