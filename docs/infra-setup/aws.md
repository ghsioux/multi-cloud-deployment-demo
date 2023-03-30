# AWS infra setup

First, be sure to source the `env.sh` file created during the [environment setup](../env-setup/env-setup.md):

```bash
$ source env.sh
```

## AWS CLI setup

We have to configure the AWS CLI with the credentials of the AWS account you want to deploy to. You can do this by running the following command:
```bash
$ aws configure
AWS Access Key ID [None]: [your access key id]
AWS Secret Access Key [None]: [your secret access key]
Default region name [None]: [] # leave blank
Default output format [None]: json
```

## Create an ECS cluster
```bash
$ aws ecs create-cluster --cluster-name $AWS_ECS_CLUSTER_NAME --region $AWS_REGION
```

##  Create a mock ECS task definition:
 
This step is required for the [amazon-ecs-render-task-definition action](https://github.com/marketplace/actions/amazon-ecs-render-task-definition-action-for-github-actions) (see step 3 of [this documentation](https://docs.github.com/en/actions/deployment/deploying-to-your-cloud-provider/deploying-to-amazon-elastic-container-service)), which is itself a prerequisite for running the [amazon-ecs-deploy-task-definition](https://github.com/aws-actions/amazon-ecs-deploy-task-definition).

The `petclinic-task-definition.json` is included in this repository as it will be later used by the [`amazon-ecs-render-task-definition action` step](../../.github/workflows/deploy-to-aws-ecs.yml#L68-L74). It's a simple task definition that defines a single container listening on port 8080.

```bash
$ aws ecs register-task-definition --cli-input-json file://assets/aws-petclinic-ecs-task-definition.json
```

## Create the ECS service

We have created an ECS cluster and a task definition which will be used by the ECS service. We now have to create the ECS service itself, but to do so we need to either create or use already existing VPC, subnet(s) and network security group(s).

For this guide I'll use the already existing default VPC and associated subnets, and create a dedicated network security group.

```bash
# retrieve the VPC id for the VPC you want to use 
# (in this case I'm using the default VPC):
$ aws ec2 describe-vpcs --region ap-southeast-1
[...]
            "VpcId": "vpc-02a9574a67eb6f5cd",
[...]

# retrieve the subnets that belongs to the chosen VPC:
$ aws ec2 describe-subnets --region ap-southeast-1 \
    --query 'Subnets[?VpcId==`vpc-02a9574a67eb6f5cd`].SubnetId'
[
    "subnet-02714b64899533bd2",
    "subnet-056620b556eca535f",
    "subnet-059c6c88002630116"
]

# create the security group:
$ aws ec2 create-security-group --group-name spring-petclinic-sg \
    --description "Security group for demo Spring Petclinic"\
    --vpc-id vpc-02a9574a67eb6f5cd \
    --region ap-southeast-1
{
    "GroupId": "sg-09dd18aab0fb04bf1"
}

# add an inbound rule to the security group to allow traffic on port 8080:
# (PetClinic runs on port 8080)
$ aws ec2 authorize-security-group-ingress \
    --group-id sg-09dd18aab0fb04bf1 \
    --protocol tcp --port 8080 --cidr 0.0.0.0/0

# we can now create the ECS service
#
# the task-definition parameter is the name of the task definition
# we created in the previous step (see "name" in /assets/petclinic-task-definition.json)
#
# the network-configuration parameter is a JSON string that specifies the
# subnets and security groups we retrieved/created previously; we also specify
# that we want to assign a public IP address to the container so we can access it
$ aws ecs create-service \
    --cluster $AWS_ECS_CLUSTER_NAME \
    --region $AWS_REGION \
    --service-name $AWS_ECS_SERVICE_NAME \
    --task-definition spring-petclinic \
    --desired-count 1 --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-02714b64899533bd2,subnet-056620b556eca535f,subnet-059c6c88002630116],securityGroups=[sg-09dd18aab0fb04bf1],assignPublicIp=ENABLED}"
```