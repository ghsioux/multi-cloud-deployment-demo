# GCP infra setup

First, be sure to source the `env.sh` file created during the [environment setup](../env-setup/env-setup.md):

```bash
$ source env.sh
```

## GCP CLI setup

First login to GCP using the following command:

```bash
$ gcloud auth login --brief
```

Let's then configure the project we'll be using::

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
$ gcloud iam service-accounts create $SERVICE_ACCOUNT \
   --display-name="GitHub Actions Petclinic Service Account"

# assign the role to be able to use OIDC
$ gcloud projects add-iam-policy-binding $PROJECT_ID \
   --member="serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
   --role="roles/iam.serviceAccountUser"

# assign the roles to be able to create a Cloud Run service
$ gcloud projects add-iam-policy-binding $PROJECT_ID \
   --member="serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
   --role="roles/run.developer"
$ gcloud projects add-iam-policy-binding $PROJECT_ID \
   --member="serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
   --role="roles/storage.admin"

# assign the roles to be able to push images to Artifact Registry
$ gcloud projects add-iam-policy-binding $PROJECT_ID \
   --member="serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
   --role="roles/artifactregistry.writer"
```

## Configure the OIDC provider

Next, we need to configure the OIDC provider:

```bash
# create the workload identity pool
$ gcloud iam workload-identity-pools create $WORKLOAD_IDENTITY_POOL \
   --location="global" \
   --display-name="GitHub Petclinic pool"

# create the OIDC provider connected to our pool
$ gcloud iam workload-identity-pools providers create-oidc $WORKLOAD_IDENTITY_PROVIDER \
   --location="global" \
   --workload-identity-pool=$WORKLOAD_IDENTITY_POOL \
   --display-name="GitHub Petclinic provider" \
   --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.environment=assertion.environment" \
   --issuer-uri="https://token.actions.githubusercontent.com"

# get the workload identity pool id
$ WORKLOAD_IDENTITY_POOL_ID=$(gcloud iam workload-identity-pools \
   describe $WORKLOAD_IDENTITY_POOL \
   --location="global" \
   --format="value(name)")

# set the trust relationship between the service account and the OIDC provider
#
# be sure to adapt the `member` value to match 
# the name of your repository and the environment you're deploying to
#
$ gcloud iam service-accounts add-iam-policy-binding \
   $SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
   --role="roles/iam.workloadIdentityUser" \
   --member="principal://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/subject/repo:ghsioux-octodemo/spring-petclinic:environment:gcp"
```

## Allow the Cloud run service to be invoked by all users

This is required to allow the service to be accessible from the outside world (otherwise we would get some 403 errors):

```bash
# note: here "spring-petclinic" is the name of the service that will 
# be created by the GitHub Actions workflow
$ gcloud run services add-iam-policy-binding spring-petclinic \
   --member="allUsers" \
   --role="roles/run.invoker" \
   --region="$GCP_REGION"
```

## Prepare the GitHub environment secrets

Since we're using an environment called `gcp`, we'll need to create the following secret inside it:

```bash
# retrieve the workload identity provider location
$ WORKLOAD_IDENTITY_PROVIDER_LOCATION=$(gcloud iam workload-identity-pools providers \
   describe $WORKLOAD_IDENTITY_PROVIDER \
   --location="global" \
   --workload-identity-pool=$WORKLOAD_IDENTITY_POOL \
   --format="value(name)")

# craft the service account identifier
$ SERVICE_ACCOUNT_ID=$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com

# set the secrets
$ gh secret set --env gcp WORKLOAD_IDENTITY_PROVIDER --body "$WORKLOAD_IDENTITY_PROVIDER_LOCATION"
$ gh secret set --env gcp SERVICE_ACCOUNT --body "$SERVICE_ACCOUNT_ID"
```