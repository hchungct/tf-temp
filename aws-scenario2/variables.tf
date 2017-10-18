variable "myip" {}

variable "number_of_ec2_instances" {}

variable "keypair_name" {}

variable "ssh_user" {
  default = "ec2-user"
}

variable "key_path" {}
