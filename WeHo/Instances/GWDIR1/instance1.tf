#provider
provider "aws" {
  shared_credentials_file = "/home/ubuntu/.aws/credentials"
  profile = "default"
  region = "ap-southeast-1" #"${var.vpc-region}"
}

terraform {
 backend "s3" {
   bucket = "terr-test1"
   key    = "instance/master/terraform.tfstate"
   shared_credentials_file = "/home/ubuntu/.aws/credentials"
   region = "ap-southeast-1"
 }
}

resource "aws_ebs_volume" "weho-GWDir-Volume2" {
  availability_zone = "ap-southeast-1a"
  size              = 100
  encrypted         = true
  tags {
        Name = "weho-GWDir-Volume2"
    }
}


resource "aws_instance" "weho-GWDir" {

 count               =  "${var.count1}"
 ami                 =  "${var.amiid}"
 availability_zone   = "ap-southeast-1a"
 instance_type       = "${var.ec2_type}"
 key_name            = "${var.keypair}"
 vpc_security_group_ids   = "${var.sec_id}"
 subnet_id           = "${var.subnetid}"
 ebs_block_device {
      device_name  = "${var.devicename}"
      volume_type = "${var.volumetype}"
      volume_size = "${var.vsize}"
      iops        = "${var.io}"
  }
  tags {
    Name = "${var.instancename}"
  }
}

resource "aws_volume_attachment" "ebs_weho-GWDir" {
  device_name = "/dev/sda2"
  volume_id   = "${aws_ebs_volume.weho-GWDir-Volume2.id}"
  instance_id = "${aws_instance.weho-GWDir.id}"
}

/*
variable "vpc-region" {
  default = "enter the value for vpc-region"
}
*/

variable "io" {
  default = "enter the value for iops"
}
variable "vsize" {
  default = "enter the volume size"
}
variable "volumetype" {
  default = "enter volume type"
}
variable "devicename" {
  default = "enter device name"
}
variable "instancename" {}

variable "sec_id" {
  default = []
  type = "list"
}
variable "subnetid" {
  default = "enter subnet id"
}
variable "count1" {
  default = "enter the number instances"
}
variable "keypair" {
  default = "enter keypair"
}

variable "ec2_type" {
 description = "AWS EC2 Instance type"
}
variable "amiid" {
  default = "enter amid of instance"
}
