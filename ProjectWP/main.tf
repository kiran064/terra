resource "aws_security_group" "prjectWpSg" {
      vpc_id = ""
      name = "projectSG"
      description = "projectSG"
      ingress {
        cidr_blocks = [ "0.0.0.0/0" ]
        description = "ssh"
        protocol = "tcp"
        from_port = 22
        to_port = 22
      }
      ingress {
        cidr_blocks = [ "0.0.0.0/0" ]
        description = "http"
        from_port = 80
        protocol = "tcp"
        to_port = 80
      }
      egress {
        cidr_blocks = [ "0.0.0.0/0" ]
        description = "all out"
        from_port = 0
        to_port = 0
        protocol = "-1"
      }
}