#test terraform template for Azure, AWS, and GCP 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
}

resource "aws_instance" "bsfsb" {
  ami                          = "ami-0e6694e5116a0086f"
  instance_type                = "t4g.small"
  security_groups              = ["bsfsb"]
  key_name                     = "testingkey"
  #associate_public_ip_address = (known after apply)
  user_data                    = "${file("../my_cloud.sh")}"
  tags = {Name = "bsfsb"}
  root_block_device {
          volume_size = "20"

}
}