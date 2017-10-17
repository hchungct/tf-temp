REQUIREMENTS:
- An AWS account
- Terraform (v0.10.6 recommended)



NOTE:
The tf-build.sh script will setup a Scenario 2 vpc, http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Scenario2.html.
Scenario 2 vpc has both a private and public subnet.  As well as an EC2 instance in the public subnet and a database in the private subnet.
The terraform config files were created and tested with terraform version 0.10.6, it's recommended to use the same version for compatibility.
If the aws-credentials file was not provided then create a file called aws-credentials and add the IAM user (terraform-user) keys in this file.
Make sure the terraform-user IAM user has access to read, create/modify, and delete resources in ec2, ecs, rds, and vpc

The format should be:
  [terraform-user]
  aws_access_key_id = <iam_access_key>
  aws_secret_access_key = <iam_secret_key>

replace <iam_access_key> and  <iam_secret_key> with the proper values



TO RUN:
To get this to work, run the script and provide a number for the number for EC2 instances to create:

  ./tf-build.sh <number_of_instances_to_build>

The tf-build.sh script will get the public ip of the machine running the script.
Which will be passed as a variable to terraform.
Then it'll initialize terraform and get any modules, if applicable, followed by planing and building out Scenario 2


CLEAN UP:
Please remember to delete all resources that were created by typing, in the same directory the tf-build.sh script was run:

  terraform destroy -var-file="runtime_vars.tfvars"

