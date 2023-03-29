# Multi-cloud deployment demo repository

This is the demo repository associated with the blog post "".

Create your own repository by clicking the `Use this template` button on the top right of this page and follow the quickstart below.

## Repository setup

### Branch protection

In a scenario where multiple developers will collaborate on this repo, it is advised to protect the `main` branch by setting up some branch protection rules. For instance:
1. Go to `Settings` > `Branches`;
2. Click on the `Add Rules` button;
3. Set `main` (or the name of your main, production branch) as the branch name pattern;
4. Choose the protection you want (e.g `Require a pull request before merging` with n reviewers). 

See more information regarding branch protection rules [here](https://docs.github.com/en/github/administering-a-repository/defining-the-mergeability-of-pull-requests/about-protected-branches).


### `v*` tag protection

Create a tag protection rule that will protect tags matching the `v*`pattern:
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

See [Environment setup](env-setup/env-setup.md).

## Cloud infrastructure setup

See [Cloud infrastructure setup](infra-setup/).

## OIDC setup

See [OIDC setup](oidc-setup/).