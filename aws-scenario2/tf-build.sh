#!/bin/bash

# checks that the correct number of variables have been passed
if [ "$#" -ne 3 ]; then
    echo "The number of parameters given doesn't match the required amount. You must specify the number of ec2 instances, a key pair name, and the path to the private key."
else
    # gets local ip to pass as a variable to terraform
    myip=$(dig +short myip.opendns.com @resolver1.opendns.com)
    echo 'Your public IP is' $myip
    mycidr=$(echo $myip/32)
    echo 'Your CIDR block is' $mycidr
    sed "s|my_local_ip|$mycidr|" input_vars.md > whitelist_ip.md

    # passes instance count input parameter to terraform variables file
    sed "s|ec2_count|$1|" whitelist_ip.md > keypair.md

    # passes keypair name input parameter to terraform variables file
    sed "s|scenario2-keypair|$2|" keypair.md > keypath.md

    # passes private key path input parameter to terraform variables file
    sed "s|path_to_private_key|$3|" keypath.md > runtime_vars.tfvars

    # series of command to run terraform
    terraform init
    terraform get
    terraform plan -var-file="runtime_vars.tfvars" -out=sc2-build 
    terraform apply "sc2-build"
fi
