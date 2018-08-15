#provider
provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  region = "${var.vpc-region}"
}


terraform {
 backend "s3" {
   bucket = "rtccpro1"
   key    = "RTCC-WeHo/VPC/terraform.tfstate"
   region = "${var.vpc-region}"
 }
}


#resource

#vpc
resource "aws_vpc" "rtcc-weho" {
    cidr_block = "${var.vpc-cidr}"
    enable_dns_hostnames = "true"
    tags{
      Name = "${var.vpc-name}"
    }
}


#igw
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.rtcc-weho.id}"
}

#subnets
resource "aws_subnet" "rtcc-weho-public" {
  cidr_block = "${var.subnet-cidr-pub}"
  vpc_id = "${aws_vpc.rtcc-weho.id}"
  map_public_ip_on_launch = "false"
  availability_zone = "${var.az-pub}"
}


resource "aws_subnet" "rtcc-weho-private" {
  cidr_block = "${var.subnet-cidr-pvt}"
  vpc_id = "${aws_vpc.rtcc-weho.id}"
  map_public_ip_on_launch = "false"
  availability_zone = "${var.az-pvt}"
}


#nat gateway
resource "aws_eip" "WeHo-nat-eip" {
  vpc = true
}



resource "aws_nat_gateway" "WeHo-nat" {
  allocation_id = "${aws_eip.WeHo-nat-eip.id}"
  subnet_id     = "${aws_subnet.rtcc-weho-public.id}"
}


#vpn

resource "aws_vpn_gateway" "rtcc_palo_alto_vpgw" {
  vpc_id = "${aws_vpc.rtcc-weho.id}"
  tags{
    Name = "${var.vpn-VPGW-name}"
  }
}

resource "aws_customer_gateway" "rtcc_palo_alto_cgw" {
  bgp_asn = 6500
  ip_address = "12.30.244.20"
  type = "ipsec.1"
  tags{
    Name = "${var.vpn-CGW-name}"
  }
}

resource "aws_vpn_connection" "RTCC-WeHo-Palo_Alto_Firewall-VPN"{
  vpn_gateway_id = "${aws_vpn_gateway.rtcc_palo_alto_vpgw.id}"
  customer_gateway_id = "${aws_customer_gateway.rtcc_palo_alto_cgw.id}"
  type = "ipsec.1"
  static_routes_only = true
  tags{
    Name = "${var.vpn-name}"
  }
}
*/


#/*  -----> delete
#vpc peering

resource "aws_vpc_peering_connection" "rtcc_vpc_peering"{
  peer_owner_id = "${var.peering-owner-id}" #account number
  peer_vpc_id = "${var.peering-vpc-id}"
  vpc_id = "${aws_vpc.rtcc-weho.id}"
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

}



#routing


resource "aws_route" "rtcc_WeHo2dmz"{
  route_table_id = "${aws_route_table.private-rtb.id}"# ID of VPC 1 main route table
  destination_cidr_block = "172.16.0.0/20" # CIDR block / IP range for VPC 2
  vpc_peering_connection_id = "${aws_vpc_peering_connection.rtcc_vpc_peering.id}"# ID of VPC peering connection
}



resource "aws_route_table" "public-rtb" {
  vpc_id = "${aws_vpc.rtcc-weho.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
  route{
    cidr_block = "172.16.0.0/20"
    vpc_peering_connection_id = "${aws_vpc_peering_connection.rtcc_vpc_peering.id}"
  }
}

resource "aws_route_table" "private-rtb" {
  vpc_id = "${aws_vpc.rtcc-weho.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.WeHo-nat.id}"
  }
  route{
    cidr_block = "172.16.0.0/20"
    vpc_peering_connection_id = "${aws_vpc_peering_connection.rtcc_vpc_peering.id}"
  }
}


####################### Should also add peering route in DMZ subnet ######################


#routetable association
resource "aws_route_table_association" "rta-rtcc-weho-public" {
  subnet_id = "${aws_subnet.rtcc-weho-public.id}"
  route_table_id = "${aws_route_table.public-rtb.id}"
}


resource "aws_route_table_association" "rta-rtcc-weho-private" {
  subnet_id = "${aws_subnet.rtcc-weho-private.id}"
  route_table_id = "${aws_route_table.private-rtb.id}"
}


#security groups

resource "aws_security_group" "WeHo-directory-sg" {
  name = "WeHo-directory-sg"
  vpc_id = "${aws_vpc.rtcc-weho.id}"

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



resource "aws_security_group" "WeHo-Failover-Fed-SG" {
  name = "WeHo-GWDir-SG"
  vpc_id = "${aws_vpc.rtcc-weho.id}"


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
