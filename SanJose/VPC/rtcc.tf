#provider
provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  #shared_credentials_file = "AWS-Key-Cred"
  region = "${var.vpc-region}"
}


terraform {
 backend "s3" {
   bucket = "rtccpro1"
   key    = "SanJose/VPC/terraform.tfstate"
   region = "us-west-2"
 }
}


#resource

#vpc
resource "aws_vpc" "rtcc-core" {
    cidr_block = "${var.vpc-cidr-core}"
    enable_dns_hostnames = "true"
    tags{
      Name = "${var.vpc-name-core}"
    }
}


#igw
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.rtcc-core.id}"
}

#subnets
resource "aws_subnet" "rtcc-public-1" {
  cidr_block = "${var.core-subnet-cidr-pub1}"
  vpc_id = "${aws_vpc.rtcc-core.id}"
  map_public_ip_on_launch = "false"
  availability_zone = "${var.core-az-pub1}"
}

resource "aws_subnet" "rtcc-public-2" {
  cidr_block = "${var.core-subnet-cidr-pub2}"
  vpc_id = "${aws_vpc.rtcc-core.id}"
  map_public_ip_on_launch = "false"
  availability_zone = "${var.core-az-pub2}"
}

resource "aws_subnet" "rtcc-private-1" {
  cidr_block = "${var.core-subnet-cidr-pvt1}"
  vpc_id = "${aws_vpc.rtcc-core.id}"
  map_public_ip_on_launch = "false"
  availability_zone = "${var.core-az-pvt1}"
}

resource "aws_subnet" "rtcc-private-2" {
  cidr_block = "${var.core-subnet-cidr-pvt2}"
  vpc_id = "${aws_vpc.rtcc-core.id}"
  map_public_ip_on_launch = "false"
  availability_zone = "${var.core-az-pvt2}"
}

#nat gateway
resource "aws_eip" "core-nat-1-eip" {
  vpc = true
}

resource "aws_eip" "core-nat-2-eip" {
  vpc = true
}

resource "aws_nat_gateway" "core-nat-1" {
  allocation_id = "${aws_eip.core-nat-1-eip.id}"
  subnet_id     = "${aws_subnet.rtcc-public-1.id}"
}

resource "aws_nat_gateway" "core-nat-2" {
  allocation_id = "${aws_eip.core-nat-2-eip.id}"
  subnet_id     = "${aws_subnet.rtcc-public-2.id}"
}

#vpn

/*
resource "aws_vpn_gateway" "rtcc_palo_alto_vpgw" {
  vpc_id = "${aws_vpc.rtcc-core.id}"
}

resource "aws_customer_gateway" "rtcc_palo_alto_cgw" {
  bgp_asn = 6500
  ip_address = "12.30.244.20"
  type = "ipsec.1"
}

resource "aws_vpn_connection" "RTCC-Palo_Alto_Firewall"{
  vpn_gateway_id = "${aws_vpn_gateway.rtcc_palo_alto_vpgw.id}"
  customer_gateway_id = "${aws_customer_gateway.rtcc_palo_alto_cgw.id}"
  type = "ipsec.1"
  static_routes_only = true
}
*/


#/*  -----> delete
#vpc peering

resource "aws_vpc_peering_connection" "rtcc_vpc_peering"{
  peer_owner_id = "290572789794" #account number
  peer_vpc_id = "${aws_vpc.rtcc-dmz.id}"
  vpc_id = "${aws_vpc.rtcc-core.id}"
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

}



#routing


resource "aws_route" "rtcc_core2dmz"{
  route_table_id = "${aws_route_table.private-rtb-1.id}"# ID of VPC 1 main route table
  destination_cidr_block = "172.16.0.0/20" # CIDR block / IP range for VPC 2
  vpc_peering_connection_id = "${aws_vpc_peering_connection.rtcc_vpc_peering.id}"# ID of VPC peering connection
}



resource "aws_route_table" "public-rtb" {
  vpc_id = "${aws_vpc.rtcc-core.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
  route{
    cidr_block = "172.16.0.0/20"
    vpc_peering_connection_id = "${aws_vpc_peering_connection.rtcc_vpc_peering.id}"
  }
}

resource "aws_route_table" "private-rtb-1" {
  vpc_id = "${aws_vpc.rtcc-core.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.core-nat-1.id}"
  }
  route{
    cidr_block = "172.16.0.0/20"
    vpc_peering_connection_id = "${aws_vpc_peering_connection.rtcc_vpc_peering.id}"
  }
}

resource "aws_route_table" "private-rtb-2" {
  vpc_id = "${aws_vpc.rtcc-core.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.core-nat-2.id}"
  }
  route{
    cidr_block = "172.16.0.0/20"
    vpc_peering_connection_id = "${aws_vpc_peering_connection.rtcc_vpc_peering.id}"
  }
}

#routetable association
resource "aws_route_table_association" "rta-rtcc-public-1" {
  subnet_id = "${aws_subnet.rtcc-public-1.id}"
  route_table_id = "${aws_route_table.public-rtb.id}"
}

resource "aws_route_table_association" "rta-rtcc-public-2" {
  subnet_id = "${aws_subnet.rtcc-public-2.id}"
  route_table_id = "${aws_route_table.public-rtb.id}"
}

resource "aws_route_table_association" "rta-rtcc-private-1" {
  subnet_id = "${aws_subnet.rtcc-private-1.id}"
  route_table_id = "${aws_route_table.private-rtb-1.id}"
}

resource "aws_route_table_association" "rta-rtcc-private-2" {
  subnet_id = "${aws_subnet.rtcc-private-2.id}"
  route_table_id = "${aws_route_table.private-rtb-2.id}"
}

#security groups

resource "aws_security_group" "core-directory-sg" {
  name = "core-directory-sg"
  vpc_id = "${aws_vpc.rtcc-core.id}"

  ingress {
    from_port = 1433
    to_port = 1433
    protocol = "tcp"
    cidr_blocks = ["192.168.101.14/32"]
  }
  ingress {
    from_port = 554
    to_port = 562
    protocol = "tcp"
    cidr_blocks = ["172.16.0.0/16"]
  }
  ingress {
    from_port = 1434
    to_port = 1434
    protocol = "udp"
    cidr_blocks = ["192.168.101.14/32"]
  }
  ingress {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = ["172.16.15.24/32"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["192.168.0.0/16", "172.16.0.0/16"]
  }
  ingress {
    from_port = 5500
    to_port = 5500
    protocol = "tcp"
    cidr_blocks = ["192.168.0.0/16", "172.16.0.0/16", "10.20.112.32/28"]
  }
  ingress {
    from_port = 0
    to_port = 8
    protocol = "icmp"
    cidr_blocks = ["10.20.112.0/24"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}


resource "aws_security_group" "core-dss_fed-SG" {
  name = "Core-DSS&FED-SG"
  vpc_id = "${aws_vpc.rtcc-core.id}"

  ingress {
    from_port = 554
    to_port = 562
    protocol = "tcp"
    cidr_blocks = ["10.20.112.46/32"]
  }
  ingress {
    from_port = 554
    to_port = 562
    protocol = "tcp"
    cidr_blocks = ["172.16.0.0/24"]
  }

  ingress {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = ["172.16.15.24/32"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
  }
  ingress {
    from_port = 5500
    to_port = 5500
    protocol = "tcp"
    cidr_blocks = ["192.168.0.0/16", "172.16.0.0/24", "10.20.112.39/32", "10.20.112.41/32"]
  }

  ingress {
    from_port = 5004
    to_port = 5006
    protocol = "tcp"
    cidr_blocks = ["10.20.112.41/32", "172.16.0.0/24"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "Core-Failover-Dir-SG" {
  name = "Core-Failover-Dir-SG"
  vpc_id = "${aws_vpc.rtcc-core.id}"

  ingress {
    from_port = 1433
    to_port = 1433
    protocol = "tcp"
    cidr_blocks = ["192.168.100.10/32"]
  }
  ingress {
    from_port = 554
    to_port = 562
    protocol = "tcp"
    cidr_blocks = ["172.16.0.0/16"]
  }

  ingress {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = ["172.16.15.24/32"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
  }
  ingress {
    from_port = 1434
    to_port = 1434
    protocol = "tcp"
    cidr_blocks = ["192.168.100.10/32"]
  }
  ingress {
    from_port = 5500
    to_port = 5500
    protocol = "tcp"
    cidr_blocks = ["172.16.0.0/24", "192.168.0.0/16", "10.20.112.0/24"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "Core-Failover-Fed-SG" {
  name = "Core-Failover-Fed-SG"
  vpc_id = "${aws_vpc.rtcc-core.id}"


  ingress {
    from_port = 554
    to_port = 562
    protocol = "tcp"
    cidr_blocks = ["172.16.0.0/16", "192.168.0.0/16"]
  }
  ingress {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = ["172.16.15.24/32"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
  }
  ingress {
    from_port = 5004
    to_port = 5006
    protocol = "tcp"
    cidr_blocks = ["192.168.0.0/16", "172.16.0.0/16"]
  }
  ingress {
    from_port = 5500
    to_port = 5500
    protocol = "tcp"
    cidr_blocks = ["172.16.0.0/24", "192.168.0.0/16", "10.20.112.0/24"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############
####  DMZ-VPC ######
###########


/*
#provider
provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  region = "us-west-2"
}

*/


#/*  -----> delete
#resource

#vpc
resource "aws_vpc" "rtcc-dmz" {
    cidr_block = "${var.vpc-cidr-dmz}"
    enable_dns_hostnames = "true"
    tags{
      Name = "${var.vpc-name-dmz}"
    }
}

#igw
resource "aws_internet_gateway" "igw1" {
  vpc_id = "${aws_vpc.rtcc-dmz.id}"
}

#subnets
resource "aws_subnet" "dmz-public-1" {
  cidr_block = "${var.dmz-subnet-cidr-pub1}"
  vpc_id = "${aws_vpc.rtcc-dmz.id}"
  map_public_ip_on_launch = "false"
  availability_zone = "${var.dmz-az-pub1}"
}

resource "aws_subnet" "dmz-public-2" {
  cidr_block = "${var.dmz-subnet-cidr-pub2}"
  vpc_id = "${aws_vpc.rtcc-dmz.id}"
  map_public_ip_on_launch = "false"
  availability_zone = "${var.dmz-az-pub2}"
}

resource "aws_subnet" "dmz-private-1" {
  cidr_block = "${var.dmz-subnet-cidr-pvt1}"
  vpc_id = "${aws_vpc.rtcc-dmz.id}"
  map_public_ip_on_launch = "false"
  availability_zone = "${var.dmz-az-pvt1}"
}

resource "aws_subnet" "dmz-private-2" {
  cidr_block = "${var.dmz-subnet-cidr-pvt2}"
  vpc_id = "${aws_vpc.rtcc-dmz.id}"
  map_public_ip_on_launch = "false"
  availability_zone = "${var.dmz-az-pvt2}"
}

#nat gateway
resource "aws_eip" "dmz-nat-1-eip" {
  vpc = true
}

resource "aws_eip" "dmz-nat-2-eip" {
  vpc = true
}

resource "aws_nat_gateway" "dmz-nat-1" {
  allocation_id = "${aws_eip.dmz-nat-1-eip.id}"
  subnet_id     = "${aws_subnet.dmz-public-1.id}"
}

resource "aws_nat_gateway" "dmz-nat-2" {
  allocation_id = "${aws_eip.dmz-nat-2-eip.id}"
  subnet_id     = "${aws_subnet.dmz-public-2.id}"
}

/*
#vpc peering
resource "aws_vpc_peering_connection" "rtcc_vpc_peering"{
  peer_owner_id = "290572789794" #account number
  peer_vpc_id = "${aws_vpc.rtcc-core.id}"
  vpc_id = "${aws_vpc.rtcc-dmz.id}"

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

}
*/


#/*   -----> delete
#routing

resource "aws_route" "dmz2rtcc_core"{
  route_table_id = "${aws_route_table.dmz-private-rtb-1.id}"# ID of VPC 2 main route table
  destination_cidr_block = "192.168.0.0/16"# CIDR block / IP range for VPC 1
  vpc_peering_connection_id = "${aws_vpc_peering_connection.rtcc_vpc_peering.id}"# ID of VPC peering connection
}

resource "aws_route_table" "dmz-public-rtb" {
  vpc_id = "${aws_vpc.rtcc-dmz.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw1.id}"
  }
  route{
    cidr_block = "192.168.0.0/16"
    vpc_peering_connection_id = "${aws_vpc_peering_connection.rtcc_vpc_peering.id}"
  }

}

resource "aws_route_table" "dmz-private-rtb-1" {
  vpc_id = "${aws_vpc.rtcc-dmz.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.dmz-nat-1.id}"
  }

  route{
    cidr_block = "192.168.0.0/16"
    vpc_peering_connection_id = "${aws_vpc_peering_connection.rtcc_vpc_peering.id}"
  }
}

resource "aws_route_table" "dmz-private-rtb-2" {
  vpc_id = "${aws_vpc.rtcc-dmz.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.dmz-nat-2.id}"
  }
  route{
    cidr_block = "192.168.0.0/16"
    vpc_peering_connection_id = "${aws_vpc_peering_connection.rtcc_vpc_peering.id}"
  }
}

#routetable association



resource "aws_route_table_association" "rta-dmz-public-1" {
  subnet_id = "${aws_subnet.dmz-public-1.id}"
  route_table_id = "${aws_route_table.dmz-public-rtb.id}"
}

resource "aws_route_table_association" "rta-dmz-public-2" {
  subnet_id = "${aws_subnet.dmz-public-2.id}"
  route_table_id = "${aws_route_table.dmz-public-rtb.id}"
}

resource "aws_route_table_association" "rta-dmz-private-1" {
  subnet_id = "${aws_subnet.dmz-private-1.id}"
  route_table_id = "${aws_route_table.dmz-private-rtb-1.id}"
}

resource "aws_route_table_association" "rta-dmz-private-2" {
  subnet_id = "${aws_subnet.dmz-private-2.id}"
  route_table_id = "${aws_route_table.dmz-private-rtb-2.id}"
}

#security groups

resource "aws_security_group" "DMZ-GWDIR2-F-sg" {
  name = "DMZ-GWDIR2-F-sg"
  vpc_id = "${aws_vpc.rtcc-dmz.id}"


  ingress {
    from_port = 554
    to_port = 562
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8012
    to_port = 8012
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = ["172.16.15.24/32"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
  }
  ingress {
    from_port = 5500
    to_port = 5500
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 5004
    to_port = 5006
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 0
    to_port = 8
    protocol = "icmp"
    cidr_blocks = ["10.20.112.0/24"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}


resource "aws_security_group" "DEV-DMZ-GWDIR1-P-SG" {
  name = "DEV-DMZ-GWDIR1-P-SG"
  vpc_id = "${aws_vpc.rtcc-dmz.id}"

  ingress {
    from_port = 1433
    to_port = 1433
    protocol = "tcp"
    cidr_blocks = ["172.16.0.0/24", "192.168.0.0/16"]
  }
  ingress {
    from_port = 1434
    to_port = 1434
    protocol = "tcp"
    cidr_blocks = ["172.16.16.0/24", "192.168.0.0/16"]
  }
  ingress {
    from_port = 554
    to_port = 562
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8012
    to_port = 8012
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = ["172.16.15.24/32"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["172.16.0.0/16", "192.168.0.0/16"]
  }
  ingress {
    from_port = 5500
    to_port = 5500
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 5004
    to_port = 5006
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "DMZ-Redirector-SG" {
  name = "DMZ-Redirector-SG"
  vpc_id = "${aws_vpc.rtcc-dmz.id}"

  ingress {
    from_port = 433
    to_port = 433
    protocol = "tcp"
    cidr_blocks = ["172.16.0.0/16", "192.168.0.0/16"]
  }
  ingress {
    from_port = 554
    to_port = 562
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = ["172.16.15.24/32"]
  }
  ingress {
    from_port = 5004
    to_port = 5006
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 5500
    to_port = 5500
    protocol = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "RD-Gateway-SG" {
  name = "RD-Gateway-SG"
  vpc_id = "${aws_vpc.rtcc-dmz.id}"


  ingress {
    from_port = 8443
    to_port = 8443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#Variables

#VPC
variable "vpc-region"{}
variable "vpc-cidr-core"{}
variable "vpc-name-core"{}
variable "vpc-cidr-dmz"{}
variable "vpc-name-dmz"{}

#subnet

#rtcc-public-1
variable "core-subnet-cidr-pub1"{}
variable "core-az-pub1"{}

#rtcc-public-2
variable "core-subnet-cidr-pub2"{}
variable "core-az-pub2"{}

#rtcc-private-1
variable "core-subnet-cidr-pvt1"{}
variable "core-az-pvt1"{}

#rtcc-private-2
variable "core-subnet-cidr-pvt2"{}
variable "core-az-pvt2"{}


#dmz-public-1
variable "dmz-subnet-cidr-pub1"{}
variable "dmz-az-pub1"{}
#dmz-public-1
variable "dmz-subnet-cidr-pub2"{}
variable "dmz-az-pub2"{}
#dmz-public-1
variable "dmz-subnet-cidr-pvt1"{}
variable "dmz-az-pvt1"{}
#dmz-public-1
variable "dmz-subnet-cidr-pvt2"{}
variable "dmz-az-pvt2"{}

#elb

/*
resource "aws_elb" "DMZ-West-1A-LB"{
  name = "DMZ-West-1A-LB"
  availability_zone = ["us_west_1a"]
  load_balancer_type = "network"

  listener {
    instance_port =554
    instance_protocol = "tcp"
    lb_port =554
    lb_protocol = "tcp"
  }
  listener {
    instance_port =560
    instance_protocol = "tcp"
    lb_port =560
    lb_protocol = "tcp"
  }
  listener {
    instance_port =561
    instance_protocol = "tcp"
    lb_port =561
    lb_protocol = "tcp"
  }
  listener {
    instance_port =562
    instance_protocol = "tcp"
    lb_port =562
    lb_protocol = "tcp"
  }
  listener {
    instance_port =5004
    instance_protocol = "tcp"
    lb_port =5004
    lb_protocol = "tcp"
  }
  listener {
    instance_port =5005
    instance_protocol = "tcp"
    lb_port =5005
    lb_protocol = "tcp"
  }
  listener {
    instance_port =5006
    instance_protocol = "tcp"
    lb_port =5006
    lb_protocol = "tcp"
  }
  listener {
    instance_port =5500
    instance_protocol = "tcp"
    lb_port =5500
    lb_protocol = "tcp"
  }
  listener {
    instance_port =8012
    instance_protocol = "tcp"
    lb_port =8012
    lb_protocol = "tcp"
  }


  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:554/"
    interval = 30
  }
  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:560/"
    interval = 30
  }
  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:561/"
    interval = 30
  }
  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:562/"
    interval = 30
  }
  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:5004/"
    interval = 30
  }
  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:5005/"
    interval = 30
  }
  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:5006/"
    interval = 30
  }
  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:5500/"
    interval = 30
  }
  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:8012/"
    interval = 30
  }
}


resource "aws_elb" "RD-Gateway-LB"{
  name = "RD-Gateway-LB"
  availability_zone = ["us_west_1a"]
  load_balancer_type = "network"

  listener {
    instance_port =554
    instance_protocol = "tcp"
    lb_port =554
    lb_protocol = "tcp"
  }
  listener {
    instance_port =5500
    instance_protocol = "tcp"
    lb_port =5500
    lb_protocol = "tcp"
  }
  listener {
    instance_port = 8443
    instance_protocol = "tcp"
    lb_port = 8443
    lb_protocol = "tcp"
  }
  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:554/"
    interval = 30
  }
  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:5500/"
    interval = 30
  }
  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 10
    target = "TCP:8443/"
    interval = 30
  }


}
*/

/*
resource "aws_instance" "myec2" {

 count               =  "${var.count1}"
 ami                 =  "${var.amiid}"
 #availability_zone   = "us-east-1a"
 instance_type       = "${var.ec2_type}"
 key_name            = "${var.keypair}"
 vpc_security_group_ids   = "${aws_security_group.core-directory-sg.id}"
 subnet_id           = "${aws_subnet.rtcc-public-1.id}"
 ebs_block_device {
      device_name  = "${var.devicename}"
      volume_type = "${var.volumetype}"
      volume_size = "${var.vsize}"
      iops        = "${var.io}"
  }
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
*/
