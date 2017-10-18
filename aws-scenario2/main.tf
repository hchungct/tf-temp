# sets aws provider
provider "aws" {
  #Path to aws credentials file that has the iam user key to access aws services
  shared_credentials_file = "./aws-credentials"
  #Name of the profile that the iam key can be found under. User has to already be existing
  profile = "terraform-user"
  region = "us-east-1"
}

# creates a vpc for a public and private subnets
resource "aws_vpc" "scenario2-vpc" {
  cidr_block = "10.0.0.0/16"       
}

# creates an internet gateway for a vpc
resource "aws_internet_gateway" "scenario2-igw" {
  vpc_id = "${aws_vpc.scenario2-vpc.id}"
}

# creates a private subnet within the scenario2 vpc
resource "aws_subnet" "private-subnet1" {
  vpc_id     = "${aws_vpc.scenario2-vpc.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags {
    Name = "private subnet 1"
  }
}

# the aws_db_subnet_group requires a minimum of 2 different az so creating another subnet
resource "aws_subnet" "private-subnet2" {
  vpc_id     = "${aws_vpc.scenario2-vpc.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags { 
    Name = "private subnet 2"
  }
}

# sets up a route table for a vpc
resource "aws_route_table" "sc2-private" {
  vpc_id = "${aws_vpc.scenario2-vpc.id}"
  tags {
    Name = "private route table"
  }
} 

# associates route table to a subnet
resource "aws_route_table_association" "sc2-route-tab-asso1" {
  subnet_id = "${aws_subnet.private-subnet1.id}"
  route_table_id = "${aws_route_table.sc2-private.id}"
}

# private database subnets
resource "aws_db_subnet_group" "private-db-subnet1" {
  subnet_ids   = ["${aws_subnet.private-subnet1.id}","${aws_subnet.private-subnet2.id}"]
}

# creates a public subnet within the scenario2 vpc
resource "aws_subnet" "public-subnet1" {
  vpc_id     = "${aws_vpc.scenario2-vpc.id}"
  cidr_block = "10.0.1.0/24"
  tags {
    Name = "public subnet 1"
  }
}

# sets up route table for a vpc
resource "aws_route_table" "sc2-public" {
  vpc_id = "${aws_vpc.scenario2-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.scenario2-igw.id}"
  }
  tags {
    Name = "public route table"
  }
}

# associates route table to a subnet
resource "aws_route_table_association" "sc2-route-tab-asso2" {
  subnet_id = "${aws_subnet.public-subnet1.id}"
  route_table_id = "${aws_route_table.sc2-public.id}"
}

# security group for webserver in the scenario2-vpc
resource "aws_security_group" "webserversg" {
  name        = "webserver-sg"
  description = "sg for a webserver"
  vpc_id      = "${aws_vpc.scenario2-vpc.id}"

  # http access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # https access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ssh access from my ip
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.myip}"]
  }

  # rdp access from my ip
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${var.myip}"]
  }

  # rdp access from my ip
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "udp"
    cidr_blocks = ["${var.myip}"]
  }

  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
#    security_groups = ["${aws_security_group.databasesg.id}"]
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# security group for database
resource "aws_security_group" "databasesg" {
  name        = "database-sg"
  description = "sg for database access"
  vpc_id      = "${aws_vpc.scenario2-vpc.id}"

  # only allows access from the webserver-sg security group to the database
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = ["${aws_security_group.webserversg.id}"]
  }

  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# creates a free tier ec2 instance
resource "aws_instance" "scenario2-ec2" {
  ami = "ami-8c1be5f6"
  instance_type = "t2.micro"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.webserversg.id}"]
  subnet_id = "${aws_subnet.public-subnet1.id}"
  count = "${var.number_of_ec2_instances}"
  # the provisioner will install docker on the instance and then start the hello-world container
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y", 
      "sudo yum install -y docker",
      "sudo service docker start",
      "sudo docker run -d -p 80:5000 training/webapp:latest python app.py"
    ]
    connection {
      type     = "ssh"
      user     = "${var.ssh_user}"
      private_key = "${file("${var.key_path}")}"
      timeout  = "4m"
    }
  }
  key_name = "${var.keypair_name}"
}

# docker provider
provider "docker" {
}

resource "docker_container" "hw" {
  image = "${docker_image.hello-world.latest}"
  name  = "helloworld"
}

resource "docker_image" "hello-world" {
  name = "training/webapp:latest"
}

# creates an rds instance in a private subnet
resource "aws_db_instance" "scenario2-rds" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.6.35"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "admin"
  password             = "hchung1234"
  publicly_accessible  = "false"
  db_subnet_group_name = "${aws_db_subnet_group.private-db-subnet1.id}"
  vpc_security_group_ids = ["${aws_security_group.databasesg.id}"]
  skip_final_snapshot  = "true"
}
