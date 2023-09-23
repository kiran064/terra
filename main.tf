provider "aws" {
    region = "ap-south-1"
}

resource "aws_instance" "test" {
    ami = "ami-01a4f99c4ac11b03c"
    instance_type = "t2.micro"
    key_name = "Mykeytoall"
    vpc_security_group_ids = ["sg-0254bc20533cdfb7e"]
    tags = {
        name = "Ec2_Linux"
    }
}