
provider "aws" {
  version = "~> 2.0"
  region  = "us-east-2"
}



## creating user_system vpc network 

resource "aws_vpc" "user_system_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Private Subnet for CloudHSM and EC2 communications in Availability Zone 1
resource "aws_subnet" "cloudHSM_private_subnet_AZ_1" {
  vpc_id     = aws_vpc.user_system_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "user_system_vpc"
  }
}

# Private Subnet for CloudHSM and EC2 communications in Availability Zone 2
resource "aws_subnet" "cloudHSM_private_subnet_AZ_2" {
  vpc_id     = aws_vpc.user_system_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "user_system_vpc"
  }
}

# Private Subnet for CloudHSM and EC2 communications in Availability Zone 2
resource "aws_subnet" "cloudHSM_private_subnet_AZ_3" {
  vpc_id     = aws_vpc.user_system_vpc.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "user_system_vpc"
  }
}

# Creating HSM Cluster in Subnet 1 
resource "aws_cloudhsm_v2_cluster" "cloudhsm_v2_cluster" {
  hsm_type   = "hsm1.medium"
  subnet_ids = [aws_subnet.cloudHSM_private_subnet_AZ_1.id]

  tags = {
    Name = "user_system_vpc"
  }
}

resource "aws_cloudhsm_v2_hsm" "cloudhsm_v2_hsm" {
  subnet_id  = aws_subnet.cloudHSM_private_subnet_AZ_1.id
  cluster_id = aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.cluster_id
}

# Generate SSH key
resource "tls_private_key" "vault" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS Key Pair
resource "aws_key_pair" "vault" {
  key_name   = "vault-key"
  public_key = tls_private_key.vault.public_key_openssh
}
resource "local_file" "private_key" {
  content  = tls_private_key.vault.private_key_pem
  filename = "vault-key.pem"
}



resource "aws_instance" "utrn_gen" {
  
  ami                    = "ami-01e7ca2ef94a0ae86"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.cloudHSM_private_subnet_AZ_1.id
  vpc_security_group_ids = [aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.security_group_id, aws_security_group.allow_ssh.id]

  key_name = aws_key_pair.vault.key_name

  tags = {
    Name = "UTRN_Gen"
  }
}

# Creating Signing Server
resource "aws_instance" "Signing_Server" {

  ami                    = "ami-01e7ca2ef94a0ae86"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.cloudHSM_private_subnet_AZ_1.id
  vpc_security_group_ids = [aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.security_group_id, aws_security_group.allow_ssh.id]

  key_name = aws_key_pair.vault.key_name

  tags = {
    Name = "Signing_Server"
  }
}

# Parse and Correlate
resource "aws_instance" "parse_correlate" {

  ami                    = "ami-01e7ca2ef94a0ae86"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.cloudHSM_private_subnet_AZ_1.id
  vpc_security_group_ids = [aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.security_group_id, aws_security_group.allow_ssh.id]

  key_name = aws_key_pair.vault.key_name

  tags = {
    Name = "Parse & Correlate"
  }
}

resource "aws_instance" "conductor" {

  ami                    = "ami-01e7ca2ef94a0ae86"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.cloudHSM_private_subnet_AZ_1.id
  vpc_security_group_ids = [aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.security_group_id, aws_security_group.allow_ssh.id]

  key_name = aws_key_pair.vault.key_name

  tags = {
    Name = "Conductor"
  }
}

## Allowing SSH 
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic; Allow all outbound traffic"
  vpc_id      = aws_vpc.user_system_vpc.id


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}









