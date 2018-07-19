# Deploy Vault to AWS with Consul Storage Backend

This folder contains a Terraform module for deploying Vault to AWS (within a VPC) along with Consul as the storage backend. It can be used as-is or can be modified to work in your scenario, but should serve as a strong starting point for deploying Vault.

The Terraform code will create the following resources in a VPC and subnet that you specify in the AWS us-east-1 region:
* An AWS auto scaling group with 3 EC2 instances running Ubuntu 16.04 and Vault
* An AWS auto scaling group with 5 EC2 instances running Ubuntu 16.04 and Consul
* 2 AWS launch configurations
* 2 AWS Elastic Load Balancers
* 4 AWS security groups, one for each instance and one for each ELB.
* Security Group Rules to control ingress and egress for the instances and the ELBs.

You can deploy this in either a public or a private subnet.  But you must set elb_internal and public_ip as instructed below in both cases.

## Preparation
1. Download [terraform](https://www.terraform.io/downloads.html) and extract the terraform binary to some directory in your path.
1. Extract the files to some directory on your laptop
1. On a Linux or Mac system, export your AWS keys and AWS default region as variables. On Windows, you would use set instead of export.

```
export AWS_ACCESS_KEY_ID=<your_aws_key>
export AWS_SECRET_ACCESS_KEY=<your_aws_secret_key>
export AWS_DEFAULT_REGION=us-east-1
```
1. Edit the file vault.auto.tfvars and provide values for the variables at the top of the file that do not yet have values.
key_name = ""
vault_name_prefix = ""
consul_name_prefix = ""
vpc_id = ""
subnets = ""

key_name should be the name of an existing AWS keypair in your AWS account in the us-east-1 region. Use the name as it is shown in the AWS Console, not the name of the private key on your computer (such as "roger-vault.pem").  Of course, you'll need that private key file in order to ssh to the Vault instance that is created for you.

vault_name_prefix and consul_name_prefix can be anything you want; they affect the names of some of the resources.

vpc_id should be the id of the VPC into which you want to deploy Vault.

subnets should be the id of a subnet in one of your AWS VPCs in us-east-1. (In theory, you could list multiple subnets and separate with commas, but you only need one.)

If using a public subnet, use the following for elb_internal and public_ip:
elb_internal = false
public_ip = true

If using a private subnet, use the following for elb_internal and public_ip:
elb_internal = true
public_ip = false

Do not add quotes around true and false when setting elb_internal and public_ip.

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
address = roger-elb-1706938674.us-east-1.elb.amazonaws.com
elb_security_group = sg-b981c9ce
vault_security_group = sg-497d353e
```

You will be able to use the Vault ELB URL after Vault is initialized which you will do as follows:

1. In the AWS Console, find and select your instances and pick one.
1. Copy the instance's public DNS.
1. On a different browser tab, visit <instance_public_dns>:8200/ui.
1. You will see a Vault Initialization screen.
1. Enter 1 for both the Key Shares and Key Threshold, and click the Initialize button.
1. You will then see a screen with your initial root token and your unseal key. Be sure to copy these to a secure location so you can find them later.
1. Click the Continue button.
1. Provide your key and then your token when prompted.
1. Click the Connect button for your EC2 instance in the AWS console to find the command you can use to ssh to the instance.
1. From a directory containing your private SSH key, run that ssh command.
1. On the Vault server, run the following commands:
```
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=<your_root_token>
vault write sys/license text=<contents_of_vault_license_file>
consul license put "<contents_of_consul_license_file>"
```

1. To avoid having to export the two variables in future SSH sessions, edit /home/ubuntu/.profile, /home/ubuntu/.bash_profile, and/or /home/ubuntu/.bashrc and add the two export commands at the bottom.

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
For the last command, provide your unseal key.

Remember to repeat the last set of steps for the third instance.

Your Vault and Consul Servers are now set up and licensed.  Additionally, it is running Consul as Vault's storage backend.  You can confirm that both Vault and Consul are running with the commands `ps -ef | grep vault` and `ps -ef | grep consul`.  But if you were able to access the Vault UI, you already know both are running.

Now that you have initialized Vault, you can actually access the Vault UI using your Vault ELB: http://<Vault_ELB_address>:8200/ui.

You can also access your Consul UI through the Consul ELB: http://<Consul_ELB_address>:8500/ui.
