REQUIREMENTS:
- An AWS account
- Terraform (v0.10.6 recommended)



NOTE:
The tf-build.sh script will setup Scenario 2, http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Scenario2.html.
The terraform config files were created and tested with terraform version 0.10.6.
If the aws-credentials file was not provided then create a file called aws-credentials and add the IAM user keys in this file.

The format should be:
  [terraform-user]
  aws_access_key_id = <iam_access_key>
  aws_secret_access_key = <iam_secret_key>

replace <iam_access_key> and  <iam_secret_key> with the proper values



TO RUN:
To get this to work, run the scripy by typing, on the command line:

  ./tf-build.sh

The tf-build.sh script will get the public ip of the machine running the script.
Which will be passed as a variable to terraform.
Then it'll initialized terraform and get any modules, if applicable, followed by planing and building out Scenario 2



CLEAN UP:
Please remember to delete all resources that were created by typing:

  terraform destroy -var-file="ip_whitelist.tfvars"

