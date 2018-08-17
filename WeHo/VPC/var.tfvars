#VPC
vpc-region = "ap-southeast-1"
vpc-cidr = "172.25.0.0/16"
vpc-name = "RTCC-WeHo-2"

#subnet

#rtcc-weho-public
subnet-cidr-pub = "172.25.1.0/24"
az-pub = "ap-southeast-1a"


#rtcc-weho-private
subnet-cidr-pvt = "172.25.2.0/24"
az-pvt = "ap-southeast-1a"


#vpn
vpn-CGW-name = "RTCC-WeHo2-PaloAlto-CGW"
vpn-VPGW-name = "RTCC-WeHo2-PaloAlto-VPGW"
vpn-name = "RTCC-WeHo-Palo_Alto_Firewall-VPN"


#vpc peering
peering-owner-id = "290572789794"
peering-vpc-id ="290572789794"     #"vpc-0e1db469" #RTCC DMZ VPC ID
