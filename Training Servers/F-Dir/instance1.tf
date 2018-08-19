provider "aws" {
 region                     = "us-west-1"
 shared_credentials_file    = "~/.aws/credentials"
 profile                    = "default"
}

/*
terraform {
 backend "s3" {
   bucket = "rtccpro1"
   key    = "SanJose/Instances/F-Dir/terraform.tfstate"
   region = "us-west-2"
 }
}
*/


resource "aws_ebs_volume" "training-FDir-Volume2" {
  availability_zone = "us-west-1c"
  size              = 100
  encrypted         = true
  tags {
        Name = "training-FDir-Volume2"
    }
}

resource "aws_instance" "training-FDir" {

 count               =  "${var.count1}"
 ami                 =  "${var.amiid}"
 #availability_zone   = "us-west-2a"
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

resource "aws_volume_attachment" "ebs_att-FDir" {
  device_name = "/dev/sda2"
  volume_id   = "${aws_ebs_volume.training-FDir-Volume2.id}"
  instance_id = "${aws_instance.training-FDir.id}"
}


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
