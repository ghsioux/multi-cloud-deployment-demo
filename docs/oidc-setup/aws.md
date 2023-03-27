# AWS OIDC setup

First, be sure to source the `env.sh` file created during the [environment setup](../env-setup/env-setup.md):

```bash
$ source env.sh
```

## AWS CLI setup

We have to configure the AWS CLI with the credentials for the AWS account you want to deploy to. You can do this by running the following command:
```bash
$ aws configure
AWS Access Key ID [None]: [your access key id]
AWS Secret Access Key [None]: [your secret access key]
Default region name [None]: [leave blank since we'll specify the region in the CLI commands]
Default output format [None]: json
```

## Create the OIDC identity provider

In order to create the provider, we first need the thumbprint of the GitHub Actions OIDC provider. We can get this by running the following command:

```bash
$ GITHUB_JWKS_FQDN=$(curl --silent https://token.actions.githubusercontent.com/.well-known/openid-configuration | jq .jwks_uri| tr -d '"'|cut -d '/' -f3)

$ GITHUB_OIDC_THUMBPRINT=$(openssl s_client -showcerts -connect $GITHUB_JWKS_FQDN:443 </dev/null 2>/dev/null | openssl x509 -outform PEM | openssl x509 -noout -fingerprint -sha1 -inform pem|cut -d '=' -f2 |tr -d ':')

# the output should look something like this 
# (it may be different, but the format should be the same)
$ echo $GITHUB_OIDC_THUMBPRINT
F879ABCE0008E4EB126E0097E46620F5AAAE26AD
```

Once we have the thumbprint, we can create the OIDC identity provider:
```bash
$ aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list $GITHUB_OIDC_THUMBPRINT


# retrieve the OIDC provider ARN and store it in a variable
$ OPENID_CONNECT_PROVIDER_ARN=$(aws iam list-open-id-connect-providers\
     | jq -r ".OpenIDConnectProviderList[] | select(.Arn | contains(\"$GITHUB_JWKS_FQDN\")) | .Arn")
```

## Create and configure the IAM role

We can now create the IAM role that we'll assume when we deploy to AWS, and we'll connect it to the OIDC identity provider we created in the previous step. 

```bash
# prepare the trust policy JSON file
$ cat <<EOF > trust-policy.json
{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "RoleForGitHubActionsSprincPetClinic",
                "Effect": "Allow",
                "Principal": {
                    "Federated": "$OPENID_CONNECT_PROVIDER_ARN"
                },
                "Action": "sts:AssumeRoleWithWebIdentity",
                "Condition": {
                    "StringEquals": {
                        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                    },
                    "StringLike": {
                        "token.actions.githubusercontent.com:sub": "$AWS_OIDC_TOCKEN_SUB"
                    }
                }
            }
        ]
}
EOF

# create the role with the trust policy
$ aws iam create-role --role-name $AWS_IAM_ROLE --assume-role-policy-document file://trust-policy.json
```

We can now attach the `AmazonECS_FullAccess` policy to the role we just created:

> ⚠️ **`AmazonECS_FullAccess` is a very permissive policy. You should only use it for testing purposes. In a production environment, you should create a custom policy that only grants the permissions that your deployment needs.**

```bash
$ aws iam attach-role-policy --role-name $AWS_IAM_ROLE \
    --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess
```

## Prepare the GitHub environment secrets

We'll create a GitHub environment secret named `OIDC_ROLE_TO_ASSUME` in the environment `aws` that will contain the ARN of the IAM role we just created. This secret will be used by the [configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials) action to authenticate to AWS using OIDC.

Let's first retrieve the role ARN:
```bash
$ OIDC_ROLE_TO_ASSUME=$(aws iam get-role --role-name $AWS_IAM_ROLE | jq -r .Role.Arn)

$ echo $OIDC_ROLE_TO_ASSUME
```

Using the web UI, go to your repository, then to `Settings` > `Environments` > `aws` > `Secrets` and create a new secret named `OIDC_ROLE_TO_ASSUME` with the value of the `OIDC_ROLE_TO_ASSUME` variable.

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
$ gh secret set OIDC_ROLE_TO_ASSUME -b $OIDC_ROLE_TO_ASSUME -e aws
```