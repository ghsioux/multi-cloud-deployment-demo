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

Use the project we've created during the [infra setup](../infra-setup/gcp.md)]:

```bash
$ gcloud config set project $GCP_PROJECT_ID
```

## Enable the required services

We need to enable the APIs for IAM and OIDC:

```bash
$ gcloud services enable iamcredentials.googleapis.com
```

## Create and configure the service account

It's now time to create the service account and assign it the required roles:

```bash
$ gcloud iam service-accounts create $GCP_SERVICE_ACCOUNT \
   --display-name="GitHub Actions Petclinic Service Account"

# assign the role to be able to use OIDC
$ gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
   --member="serviceAccount:$GCP_SERVICE_ACCOUNT@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
   --role="roles/iam.serviceAccountUser"

# assign the roles to be able to create a Cloud Run service
$ gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
   --member="serviceAccount:$GCP_SERVICE_ACCOUNT@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
   --role="roles/run.developer"
$ gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
   --member="serviceAccount:$GCP_SERVICE_ACCOUNT@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
   --role="roles/storage.admin"

# assign the role to be able to push images to Artifact Registry
$ gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
   --member="serviceAccount:$GCP_SERVICE_ACCOUNT@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
   --role="roles/artifactregistry.writer"
```

## Configure the OIDC provider

Next, we need to configure the OIDC provider:

```bash
# create the workload identity pool
$ gcloud iam workload-identity-pools create $GCP_WORKLOAD_IDENTITY_POOL \
   --location="global" \
   --display-name="GitHub Petclinic pool"

# create the OIDC provider connected to our pool
$ gcloud iam workload-identity-pools providers create-oidc $GCP_WORKLOAD_IDENTITY_PROVIDER \
   --location="global" \
   --workload-identity-pool=$GCP_WORKLOAD_IDENTITY_POOL \
   --display-name="GitHub Petclinic provider" \
   --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.environment=assertion.environment" \
   --issuer-uri="https://token.actions.githubusercontent.com"

# get the workload identity pool id
$ WORKLOAD_IDENTITY_POOL_ID=$(gcloud iam workload-identity-pools \
   describe $GCP_WORKLOAD_IDENTITY_POOL \
   --location="global" \
   --format="value(name)")

# set the trust relationship between the service account and the OIDC provider
$ gcloud iam service-accounts add-iam-policy-binding \
   $GCP_SERVICE_ACCOUNT@$GCP_PROJECT_ID.iam.gserviceaccount.com \
   --role="roles/iam.workloadIdentityUser" \
   --member="principal://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/subject/$GCP_OIDC_IDENTITY"
```

## Allow the Cloud run service to be invoked by all users

This is required to allow the service to be accessible from the outside world (otherwise we would get some 403 errors):

```bash
# note 1: here "spring-petclinic" is the name of the service that will 
# be created by the GitHub Actions workflow (see ../../.github/workflows/multi-cloud-deployment.yml)
#
# note 2: this command might fail if the service is not yet created 
# (which is the case if the workflow has not been triggered yet)
# you might want to run this command after the container app has been deployed
$ gcloud run services add-iam-policy-binding spring-petclinic \
   --member="allUsers" \
   --role="roles/run.invoker" \
   --region="$GCP_REGION"
```

## Prepare the GitHub environment secrets

We'll create two GitHub environment secrets named in the environment `gcp` that will contain the information related to the service principal created above. These secret will be used by the [google-github-actions/auth](https://github.com/google-github-actions/auth) action to authenticate to GCP using OIDC.

Let's first retrieve the values:
```bash
# retrieve the workload identity provider location
$ WORKLOAD_IDENTITY_PROVIDER_LOCATION=$(gcloud iam workload-identity-pools providers \
   describe $GCP_WORKLOAD_IDENTITY_PROVIDER \
   --location="global" \
   --workload-identity-pool=$GCP_WORKLOAD_IDENTITY_POOL \
   --format="value(name)")

# craft the service account identifier
$ SERVICE_ACCOUNT_ID=$GCP_SERVICE_ACCOUNT@$GCP_PROJECT_ID.iam.gserviceaccount.com

$ echo $WORKLOAD_IDENTITY_PROVIDER_LOCATION
$ echo $SERVICE_ACCOUNT_ID
```

Using the web UI, go to your repository, then to `Settings` > `Environments` > `gcp` > `Secrets` and create the three secrets:
* a secret named `WORKLOAD_IDENTITY_PROVIDER` with the value of the `WORKLOAD_IDENTITY_PROVIDER` variable;
* a secret named `SERVICE_ACCOUNT` with the value of the `SERVICE_ACCOUNT` variable;

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
$ gh secret set --env gcp WORKLOAD_IDENTITY_PROVIDER --body "$GCP_WORKLOAD_IDENTITY_PROVIDER_LOCATION"
$ gh secret set --env gcp SERVICE_ACCOUNT --body "$GCP_SERVICE_ACCOUNT_ID"
```