variable REGION {
    default = "ap-south-1"
}

variable AMI {
    type = map
    default = {
        ap-south-1 = "ami-0d162611e9535c4e3"
        us-east-1 = "ami-0aa7d40eeae50c9a9"
    }
}

variable key {
    type = map
    default = {
        ap-south-1 = "Mykeytoall"
        us-east-1 = "mykeynvirginia"
    }
}

variable sgroup {
    type = map
    default = {
        ap-south-1 = ["sg-0254bc20533cdfb7e"]
        us-east-1 = ["sg-0a8a36e9ce7f0d174"]
    } 
}

variable type {
    default = "t2.micro"
  
}