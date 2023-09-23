provider "aws" {
    region = var.REGION
}

variable REGION {
    default = "ap-south-1"
}

variable AMI {
    type = map
    default = {
        ap-south-1 = "ami-0376ec8eacdf70aae"
        us-east-1 = "ami-0aa7d40eeae50c9a9"
    }
}

variable type {
    default = "t2.micro"
  
}

resource "aws_vpc" "Project" {
    cidr_block = "120.0.0.0/16"
    tags = {
        Name = "Project"
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

resource "aws_subnet" "PrivateSubnet" {
    vpc_id = aws_vpc.Project.id
    cidr_block = "120.0.1.0/24"
    availability_zone = "${var.REGION}a"
    tags = {
      "Name" = "PrivateSubnet"
    }
}

resource "aws_subnet" "PublicSubnet" {
    vpc_id = aws_vpc.Project.id
    cidr_block = "120.0.0.0/24"
    map_public_ip_on_launch = true
    availability_zone = "${var.REGION}a"
    tags = {
      "Name" = "PublicSubnet"
    }
}

resource "aws_internet_gateway" "Project_gateway" {
    vpc_id = aws_vpc.Project.id
    tags = {
        Name = "project_IG"
    }  
}

resource "aws_eip" "Nat_eip" {
        tags = {
                Name = "test-eip"
        }
}

resource "aws_nat_gateway" "privateIG" {
    allocation_id = aws_eip.Nat_eip.allocation_id
    subnet_id = aws_subnet.PublicSubnet.id
    tags = {
        Name = "privateIG"
    }
    depends_on = [
      aws_internet_gateway.Project_gateway
    ]
}

resource "aws_route_table" "public_route" {
    vpc_id = aws_vpc.Project.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.Project_gateway.id
    }
    tags = {
      "Name" = "PublicRouteTable"
    }
}

resource "aws_route" "NatRoute" {
    route_table_id = aws_vpc.Project.main_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.privateIG.id
}

resource "aws_route_table_association" "publictable1" {
    route_table_id = aws_route_table.public_route.id
    subnet_id = aws_subnet.PublicSubnet.id
}

resource "aws_route_table_association" "private_route1" {
    route_table_id = aws_vpc.Project.main_route_table_id
    subnet_id = aws_subnet.PrivateSubnet.id
}
/*
resource "aws_security_group" "projectSG" {
    vpc_id = aws_vpc.Project.id
    name = "public_SG"
    description = "public_rule"
    ingress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "ssh"
      from_port = 22
      protocol = "tcp"
      to_port = 22
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

    ingress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "tomcat"
      from_port = 8080
      protocol = "tcp"
      to_port = 8080
    }
    ingress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "rdp"
      from_port = 3389
      protocol = "tcp"
      to_port = 3389
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
*/
resource "aws_security_group" "projectSGPrivate" {
    vpc_id = aws_vpc.Project.id
    name = "private_SG"
    description = "private_rule"
    ingress {
      cidr_blocks = [aws_vpc.Project.cidr_block]
      description = "ssh"
      from_port = 22
      protocol = "tcp"
      to_port = 22
    }

    ingress {
      cidr_blocks = [aws_vpc.Project.cidr_block]
      description = "http"
      from_port = 80
      protocol = "tcp"
      to_port = 80
    }

    ingress {
      cidr_blocks = [aws_vpc.Project.cidr_block]
      description = "https"
      from_port = 443
      protocol = "tcp"
      to_port = 443
    }

    ingress {
      cidr_blocks = [aws_vpc.Project.cidr_block]
      description = "tomcat"
      from_port = 8080
      protocol = "tcp"
      to_port = 8080
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

resource "aws_instance" "Ec2_Linux" {
    ami = var.AMI[var.REGION]
    instance_type = var.type
    key_name = aws_key_pair.projectKey.key_name
    subnet_id = aws_subnet.PrivateSubnet.id
    security_groups = [aws_security_group.projectSGPrivate.id]
    tags = {
      Name = "Ec2_Linux"
    }
}
/*
resource "aws_instance" "AnsibleController" {
    ami = var.AMI[var.REGION]
    instance_type = var.type
    key_name = aws_key_pair.projectKey.key_name
    subnet_id = aws_subnet.subnet_devops.id
    security_groups = [aws_security_group.projectSGPrivate.id]
    iam_instance_profile = "cloudAgent"
    user_data = <<EOF
    #!/bin/bash
yum install git java-1.8.0-openjdk-devel.x86_64 awslogs -y
sudo amazon-linux-extras install ansible2 -y

EOF
    tags = {
      Name = "AnsibleController"
    }
}

resource "aws_instance" "DevEc2" {
    ami = var.AMI[var.REGION]
    instance_type = var.type
    key_name = aws_key_pair.projectKey.key_name
    subnet_id = aws_subnet.subnet_dev.id
    security_groups = [aws_security_group.projectSGPrivate.id]
    count = 2
    user_data = <<EOF
    #!/bin/bash
file=/etc/ssh/sshd_config
cp -p $file $file.old &&
while read key other
do
 case $key in
 PasswordAuthentication) other=yes;;
 PermitRootLogin) other=yes;;
 esac
 echo "$key $other"
done < $file.old > $file

EOF
    tags = {
      Name = "DevEc2"
    }  
}

resource "aws_instance" "QaEc2" {
    ami = var.AMI[var.REGION]
    instance_type = var.type
    key_name = aws_key_pair.projectKey.key_name
    subnet_id = aws_subnet.subnet_qa.id
    security_groups = [aws_security_group.projectSGPrivate.id]
    count = 2
    user_data = <<EOF
    #!/bin/bash
file=/etc/ssh/sshd_config
cp -p $file $file.old &&
while read key other
do
 case $key in
 PasswordAuthentication) other=yes;;
 PermitRootLogin) other=yes;;
 esac
 echo "$key $other"
done < $file.old > $file

EOF
    tags = {
      Name = "QaEc2"
    }  
}

resource "aws_instance" "UatEc2" {
    ami = var.AMI[var.REGION]
    instance_type = var.type
    key_name = aws_key_pair.projectKey.key_name
    subnet_id = aws_subnet.subnet_uat.id
    security_groups = [aws_security_group.projectSGPrivate.id]
    count = 2
    user_data = <<EOF
    #!/bin/bash
file=/etc/ssh/sshd_config
cp -p $file $file.old &&
while read key other
do
 case $key in
 PasswordAuthentication) other=yes;;
 PermitRootLogin) other=yes;;
 esac
 echo "$key $other"
done < $file.old > $file

EOF
    tags = {
      Name = "UatEc2"
    }  
}

resource "aws_instance" "jumpping_Linux" {
    ami = var.AMI[var.REGION]
    instance_type = var.type
    key_name = aws_key_pair.projectKey.key_name
    subnet_id = aws_subnet.subnet_jumpping.id
    security_groups = [aws_security_group.projectSG.id]
    user_data = <<EOF
    #!/bin/bash
file=/etc/ssh/sshd_config
cp -p $file $file.old &&
while read key other
do
 case $key in
 PasswordAuthentication) other=yes;;
 PermitRootLogin) other=yes;;
 esac
 echo "$key $other"
done < $file.old > $file

EOF
    tags = {
      Name = "jumpping_Linux"
    }  
}

resource "aws_instance" "JumppingServer" {
    ami = "ami-077d687accca02dc1"
    instance_type = var.type
    key_name = var.key[var.REGION]
    subnet_id = aws_subnet.subnet_jumpping.id
    security_groups = [aws_security_group.projectSG.id]
    tags = {
      Name = "JumppingServer"
    }
}*/

output "public_ip" {
    value = aws_instance.Ec2_Linux.public_ip
}
/*
output "private_ip" {
    value = ["Uat", aws_instance.UatEc2.*.private_ip, 
    "Qa", aws_instance.QaEc2.*.private_ip,
    "Dev", aws_instance.DevEc2.*.private_ip,
    "Ansible", aws_instance.AnsibleController.private_ip,
    "Jenkins", aws_instance.Jenkins.private_ip]
}

resource "local_file" "hosts" {
    filename = "hosts"
    count = 2
    content = "[Dev]\n${aws_instance.DevEc2[count.index].private_ip} ansible_ssh_user=ansible\n[Qa]\n${aws_instance.QaEc2[count.index].private_ip} ansible_ssh_user=ansible\n[Uat]\n${aws_instance.UatEc2[count.index].private_ip} ansible_ssh_user=ansible\n"
}*/