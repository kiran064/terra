resource "aws_vpc" "Project" {
    cidr_block = "120.0.0.0/16"
    tags = {
        Name = "Project"
    }
}

resource "aws_subnet" "subnet_dev" {
    vpc_id = aws_vpc.Project.id
    cidr_block = "120.0.1.0/24"
    availability_zone = "${var.REGION}a"
    tags = {
      "Name" = "Dev"
    }
}

resource "aws_subnet" "subnet_qa" {
    vpc_id = aws_vpc.Project.id
    cidr_block = "120.0.2.0/24"
    availability_zone = "${var.REGION}b"
    tags = {
      "Name" = "Qa"
    }
}

resource "aws_subnet" "subnet_uat" {
    vpc_id = aws_vpc.Project.id
    cidr_block = "120.0.3.0/24"
    availability_zone = "${var.REGION}a"
    tags = {
      "Name" = "Uat"
    }
}

resource "aws_subnet" "subnet_devops" {
    vpc_id = aws_vpc.Project.id
    cidr_block = "120.0.4.0/24"
    availability_zone = "${var.REGION}b"
    tags = {
      "Name" = "Devops"
    }
}

resource "aws_subnet" "subnet_jumpping" {
    vpc_id = aws_vpc.Project.id
    cidr_block = "120.0.0.0/24"
    map_public_ip_on_launch = true
    availability_zone = "${var.REGION}a"
    tags = {
      "Name" = "Jumpping"
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
    subnet_id = aws_subnet.subnet_jumpping.id
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

resource "aws_route_table_association" "publictable1" {
    route_table_id = aws_route_table.public_route.id
    subnet_id = aws_subnet.subnet_jumpping.id
}

resource "aws_route_table_association" "private_route1" {
    route_table_id = aws_vpc.Project.main_route_table_id
    subnet_id = aws_subnet.subnet_dev.id
}

resource "aws_route_table_association" "private_route2" {
    route_table_id = aws_vpc.Project.main_route_table_id
    subnet_id = aws_subnet.subnet_qa.id
}

resource "aws_route_table_association" "private_route3" {
    route_table_id = aws_vpc.Project.main_route_table_id
    subnet_id = aws_subnet.subnet_uat.id
}

resource "aws_route_table_association" "private_route4" {
    route_table_id = aws_vpc.Project.main_route_table_id
    subnet_id = aws_subnet.subnet_devops.id
}



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
    
    egress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "All_traffic"
      from_port = 0
      protocol = "-1"
      self = false
      to_port = 0
    }
}

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

resource "aws_instance" "new" {
    ami = var.AMI[var.REGION]
    instance_type = var.type
    key_name = var.key[var.REGION]
    subnet_id = aws_subnet.subnet_jumpping.id
    security_groups = [aws_security_group.projectSG.id]
    user_data = <<EOF
    #!/bin/bash
yum update -y
sudo yum install httpd -y
cd /
sudo mkdir webfiles
cd webfiles
wget https://www.tooplate.com/zip-templates/2121_wave_cafe.zip
unzip 2121_wave_cafe.zip
sudo cp -r ./2121_wave_cafe/* /var/www/html/
sudo service httpd start
sudo systemctl restart httpd

EOF

}

output "public_ip" {
    value = aws_instance.new.public_ip
}