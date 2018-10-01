# Deploy Vault to AWS with Consul Storage Backend

This folder contains a Terraform module for deploying Vault to AWS along with Consul as the storage backend. It can be used as-is or can be modified to work in your scenario, but should serve as a starting point for deploying Vault. It can be used with Ubuntu 16.04 or RHEL 7.5.

This branch assumes that you already have a VPC with at least one subnet (public or private), an IAM instance profile associated with an IAM role having required policy, and properly configured security groups. To provision the IAM constructs and security groups, see the create-iam-and-sgs branch of this repository.

The Terraform code will create the following resources in a VPC and subnet that you specify in the AWS us-east-1 region:
* An AWS auto scaling group with 3 EC2 instances running Vault on RHEL 7.5 or Ubuntu 16.04 (depending on the AMI passed to the ami variable)
* An AWS auto scaling group with 3 EC2 instances running Consul on RHEL 7.5 or Ubuntu 16.04 (depending on the AMI passed to the ami variable)
* 2 AWS launch configurations
* 2 AWS Elastic Load Balancers, one for Vault and one for Consul

You can deploy this in either a public or a private subnet.  But you must set elb_internal and public_ip as instructed below in both cases. The VPC should have at least one subnet with 2 or 3 being preferred for high availability.

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

Be sure to set unzip_command to the appropriate command for Ubuntu or RHEL, depending on your AMI.

Set instance_profile_name to the name of your IAM instance profile which will be the same as the name of an IAM role if you created that role in the AWS Console.

Set vault_sg_id to the ID of the security group you are providing for use by the Vault and Consul EC2 instances.

Set elb_sg_id to the ID of the security group you are providing for use by the Vault and Consul Elastic Load Balancers.

Set ami to the ID of a Ubuntu 16.04 or RHEL 7.5 AMI. Public Ubuntu AMIs include ami-759bc50a or ami-059eeca93cf09eebd.  A public RHEL 7.5 AMI is ami-6871a115.

Set instance_type to the size you want to use for the EC2 instances.

key_name should be the name of an existing AWS keypair in your AWS account in the us-east-1 region. Use the name as it is shown in the AWS Console, not the name of the private key on your computer.  Of course, you'll need that private key file in order to ssh to the Vault instance that is created for you.

vault_name_prefix and consul_name_prefix can be anything you want; they affect the names of some of the resources.

vpc_id should be the id of the VPC into which you want to deploy Vault.

subnets should be the ids of one or more subnets in your AWS VPC in us-east-1. (You can also list multiple subnets and separate them with commas, but you only need one.)

If using a public subnet, use the following for elb_internal and public_ip:
elb_internal = false
public_ip = true

If using a private subnet, use the following for elb_internal and public_ip:
elb_internal = true
public_ip = false

Do not add quotes around true and false when setting elb_internal and public_ip.

The owner and ttl variables are intended for use by HashiCorp employees and will be ignored for customers.  You can set owner to your name or email.

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
consul_address = benchmark-consul-elb-387787750.us-east-1.elb.amazonaws.com
vault_address = benchmark-vault-elb-783003639.us-east-1.elb.amazonaws.com
```

You will be able to use the Vault ELB URL after Vault is initialized which you will do as follows:

1. In the AWS Console, find and select your Vault instances and pick one.
1. Click the Connect button for your selected Vault instance to find the command you can use to ssh to the instance.
1. From a directory containing your private SSH key, run that ssh command.
1. On the Vault server, run the following commands:

```
export VAULT_ADDR=http://127.0.0.1:8200
vault operator init -key-shares=1 -key-threshold=1
```
The init command will show you your root token and unseal key. (In a real production environment, you would specify `-key-shares=5 -key-threshold=3`.)
```
export VAULT_TOKEN=<your_root_token>
vault operator unseal
```
Provide your unseal key when prompted. If you selected a key-threshold greater than 1, repeat the last command until the first Vault instance is unsealed.

1. If installing evaluation Vault Enterprise and Consul Enterprise binaries, please apply the Vault and Consul license files given to you by HashiCorp.

```
vault write sys/license text=<contents_of_vault_license_file>
consul license put "<contents_of_consul_license_file>"
```

1. To avoid having to export VAULT_ADDR and VAULT_TOKEN in future SSH sessions, edit /home/ubuntu/.profile, /home/ubuntu/.bash_profile, and/or /home/ec2-user/.bash_profile and add the two export commands at the bottom.

Please do the following additional steps for your second and third Vault nodes:

1. In the AWS Console, find and select your instances and pick the second (or third) one.
1. Click the Connect button for your EC2 instance in the AWS console to find the command you can use to ssh to the instance.
1. From a directory containing your private SSH key, run that ssh command.
1. On the Vault server, run the following commands:

```
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=<your_root_token>
vault operator unseal
```
For the last command, provide your unseal key. If you selected a key-threshold greater than 1, repeat the last command until the Vault instance is unsealed.

Remember to repeat the last set of steps for the third instance.

Your Vault and Consul Servers are now set up and licensed.  Additionally, it is running Consul as Vault's storage backend.  You can confirm that both Vault and Consul are running with the commands `ps -ef | grep vault` and `ps -ef | grep consul`.  But if you were able to access the Vault UI, you already know both are running.

Now that you have initialized Vault, you can actually access the Vault UI using your Vault ELB: http://<Vault_ELB_address>:8200/ui.

You can also access your Consul UI through the Consul ELB: http://<Consul_ELB_address>:8500/ui.
