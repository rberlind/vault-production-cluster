# Deploy IAM resources and Security Groups for use by Vault/Consul

This branch of this repository contains Terraform code for provisioning IAM constructs and security groups into an existing VPC so that you can then deploy Vault and Consul as the storage backend to the same AWS VPC, leveraging the resources created by this branch. To do that, you will want to use the asgs-instances-elbs branch of this repository.

Note that if you are allowed to provision IAM resources and security groups, then you could use the master branch of this repository to provision everything provisioned by this branch and the asgs-instances-elbs branch in a single Terraform configuration.

The Terraform code will create the following resources in a VPC and subnet that you specify in the AWS us-east-1 region:
* IAM instance profile, IAM role, IAM policy, and associated IAM policy documents
* 2 AWS security groups, one for the Vault and Consul EC2 instances and one for the ELBs.
* Security Group Rules to control ingress and egress for the instances and the ELBs. These attempt to limit most traffic to inside and between the two security groups, but do allow the following broader access:
** inbound SSH access on port 22 from anywhere
** inbound access to the ELBs on ports 8200 for Vault and 8500 for Consul
** outbound calls on port 443 to anywhere (so that the installation scripts can download the vault and consul binaries)
After installation, those broader security group rules could be made tighter.

You can deploy this in either a public or a private subnet. The VPC should have at least one subnet with 2 or 3 being preferred for high availability.

## Preparation
1. Download [terraform](https://www.terraform.io/downloads.html) and extract the terraform binary to some directory in your path.
1. Clone this repository to some directory on your laptop
1. On a Linux or Mac system, export your AWS keys and AWS default region as variables. On Windows, you would use set instead of export. You can also export AWS_SESSION_TOKEN if you need to use an MFA token to provision resources in AWS.

```
export AWS_ACCESS_KEY_ID=<your_aws_key>
export AWS_SECRET_ACCESS_KEY=<your_aws_secret_key>
export AWS_DEFAULT_REGION=us-east-1
export AWS_SESSION_TOKEN=<your_token>
```
1. Edit the file vault.auto.tfvars and provide values for the variables at the top of the file that do not yet have values.

vpc_id should be the id of the VPC into which you want to deploy Vault.

vault_name_prefix and consul_name_prefix can be anything you want; they affect the names of some of the resources.

## Deployment
To actually deploy with Terraform, simply run the following two commands:

```
terraform init
terraform apply
```
When the second command asks you if you want to proceed, type "yes" to confirm.

You should get outputs at the end of the apply showing something like the following:
```
Outputs:
iam_profile_name = benchmark-vault20181001135800895900000002
vault_elb_security_group = sg-09ee1199992b803f7
vault_security_group = sg-0a4c0e2f499e2e0cf
```

You can now use the asgs-instances-elbs branch of this repository to provision the auto scaling groups, elastic load balancers, and EC2 instances that will run your Vault and Consul servers.
