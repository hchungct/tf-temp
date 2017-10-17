#!/bin/bash

# checks that the correct number of variables have been passed
if [ "$#" -ne 1 ]; then
    echo "The EC2 instance count parameter was not given.  Please specify the number of instances to launch."
else
    # gets local ip to pass as a variable to terraform
    myip=$(dig +short myip.opendns.com @resolver1.opendns.com)
    echo 'Your public IP is' $myip
    mycidr=$(echo $myip/32)
    echo 'Your CIDR block is' $mycidr
    sed "s|my_local_ip|$mycidr|" input_vars.md > whitelist_ip.md

    # passes input parameters to terraform variables file
    sed "s|ec2_count|$1|" whitelist_ip.md > runtime_vars.tfvars

    # series of command to run terraform
    terraform init
    terraform get
    terraform plan -var-file="runtime_vars.tfvars" -out=sc2-build 
    terraform apply "sc2-build"
fi
