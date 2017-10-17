#!/bin/bash

# gets local ip to pass as a variable to terraform
myip=$(dig +short myip.opendns.com @resolver1.opendns.com)
echo 'Your public IP is' $myip
mycidr=$(echo $myip/32)
echo 'Your CIDR block is' $mycidr
sed "s|my_local_ip|$mycidr|" ip_address.md > whitelist_ip.tfvars

#series of command to run terraform
#terraform init
#terraform get
#terraform plan -var-file="ip_whitelist.tfvars"
#terraform apply -var-file="ip_whitelist.tfvars"

