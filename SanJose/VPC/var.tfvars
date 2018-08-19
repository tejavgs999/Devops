#VPC
vpc-region = "us-west-2"
vpc-cidr-core = "192.168.0.0/16"
vpc-name-core = "RTCC-Core-SanJose"
vpc-cidr-dmz = "172.16.0.0/20"
vpc-name-dmz = "RTCC-DMZ-SanJose"

#subnet

#rtcc-public-1
core-subnet-cidr-pub1 = "192.168.102.0/24"
core-az-pub1 = "us-west-2a"

#rtcc-public-2
core-subnet-cidr-pub2 = "192.168.103.0/24"
core-az-pub2 = "us-west-2c"

#rtcc-private-1
core-subnet-cidr-pvt1 = "192.168.100.0/24"
core-az-pvt1 = "us-west-2a"

#rtcc-private-2
core-subnet-cidr-pvt2 = "192.168.101.0/24"
core-az-pvt2 = "us-west-2c"


#dmz-public-1
dmz-subnet-cidr-pub1 = "172.16.13.0/24"
dmz-az-pub1 = "us-west-2a"
#dmz-public-2
dmz-subnet-cidr-pub2 = "172.16.12.0/24"
dmz-az-pub2 = "us-west-2c"
#dmz-private-1
dmz-subnet-cidr-pvt1 = "172.16.14.0/24"
dmz-az-pvt1 = "us-west-2a"
#dmz-private-2
dmz-subnet-cidr-pvt2 = "172.16.15.0/24"
dmz-az-pvt2 = "us-west-2c"
