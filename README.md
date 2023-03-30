# Multi-cloud deployment demo repository 🚀

This is the demo repository associated with the blog post "" .

Create your own repository from this one by clicking the `Use this template` button on the top right of this page, and follow the quickstart below.

> ⚠️ **As explained in the blog post, this is for fun and experiment only, and not for production!**

## Repository setup

### Branch protection

In a scenario where multiple developers would collaborate on this repo, it is advised to protect the `main` branch by setting up some branch protection rules. For instance:
1. Go to `Settings` > `Branches`;
2. Click on the `Add Rules` button;
3. Set `main` (or the name of your main, production branch) as the branch name pattern;
4. Choose the protection you want (e.g `Require a pull request before merging` with ___n___ reviewers). 

See more information regarding branch protection rules [here](https://docs.github.com/en/github/administering-a-repository/defining-the-mergeability-of-pull-requests/about-protected-branches).


### `v*` tag protection

Create a tag protection rule that will protect the creation of tags matching the `v*` pattern:
1. Go to `Settings` > `Tags`;
2. Click on the `Add Rules` button;
3. Set `v*` as the tag name pattern;

See more information regarding tag protection rules [here](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/configuring-tag-protection-rules).

### Environments

Create three environments named `aws`, `azure` and `gcp`, that will be used for the three cloud providers within the Actions workflows:
1. Go to `Settings` > `Environments`;
2. Click on the `New environment` button;
3. Set the name of the environment to `aws` (resp. `azure` and `gcp`);
4. Click on the `Configure environment` button;
5. Optionally, set the `Environment protection rules` to `Required reviewers` with the number of required reviewers according to your needs.

See more information regarding environments [here](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment).

## Environment file setup

See [Environment setup](./docs/env-setup/env-setup.md).

## Cloud infrastructure setup

See [Cloud infrastructure setup](./docs/infra-setup/).

## OIDC setup

See [OIDC setup](./docs/oidc-setup/).

## Before you trigger a first deployment

You should have a look at [how the three reusable workflows are called](.github/workflows/multi-cloud-deployment.yml#L113-L177) and read the various comments to adapte the parameters to your needs.

## How to trigger

As a repository admin, you can trigger the ["🚀 Multi-cloud deployment demo" workflow](.github/workflows/multi-cloud-deployment.yml):
* by creating a release with a tag matching the `v*` pattern;
* manually on a tag matching the `v*` pattern.

## After the first successful deployment 

If you get a 403 error when trying to access the Cloud run service, you might want to allow all users to invoke the service. To do so, run the following command:

```bash
#
# note: here "spring-petclinic" is the name of the service that will 
# be created by the GitHub Actions workflow (see ../../.github/workflows/multi-cloud-deployment.yml#169)
#
$ gcloud run services add-iam-policy-binding spring-petclinic \
   --member="allUsers" \
   --role="roles/run.invoker" \
   --region="$GCP_REGION"
```