provider "aws" {
    region = "ap-south-1"
}

variable AMI {
    default= "ami-0d162611e9535c4e3"
}

resource "aws_vpc" "Project" {
    cidr_block = "10.10.0.0/24"
    tags = {
        Name = "TestVpc"
    }
}

resource "aws_subnet" "Public" {
    vpc_id = aws_vpc.Project.id
    cidr_block = "10.10.1.0/28"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    tags = {
      "Name" = "Public"
    }
}

resource "tls_private_key" "rsa" {
    algorithm = "RSA"
    rsa_bits = 4096  
}

resource "aws_key_pair" "projectKey" {
    key_name = "projectKey"
    public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "keystrorage" {
    filename = "projectKey.pem"
    content = tls_private_key.rsa.private_key_pem
}

resource "aws_internet_gateway" "Project_gateway" {
    vpc_id = aws_vpc.Project.id
    tags = {
        Name = "project_IG"
    }  
}

resource "aws_route" "PublicRoute" {
    route_table_id = aws_vpc.Project.main_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Project_gateway.id
}

resource "aws_eip" "EIP" {
        tags = {
                Name = "test_eip"
        }
}


resource "aws_security_group" "projectSG" {
    vpc_id = aws_vpc.Project.id
    name = "public_SG"
    description = "public_rule"
    ingress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "ssh"
      from_port = 44332
      protocol = "tcp"
      to_port = 44332
    }

    ingress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "http"
      from_port = 80
      protocol = "tcp"
      to_port = 80
    }

    ingress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "https"
      from_port = 443
      protocol = "tcp"
      to_port = 443
    }
    
    egress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "All_traffic"
      from_port = 0
      protocol = "-1"
      self = false
      to_port = 0
    }
}

resource "aws_instance" "Linux2" {
    ami = var.AMI
    instance_type = "t2.micro"
    key_name = aws_key_pair.projectKey.key_name
    subnet_id = aws_subnet.Public.id
    security_groups = [aws_security_group.projectSG.id]
    count = 1
    user_data = <<EOF
    #!/bin/bash
yum update -y
yum install httpd -y
cd /var/www/html/
echo "<H1> Test Html file <H1>" > index.html
service httpd start
systemctl restart httpd

EOF
    tags = {
      Name = "Linux2"
    }  
}