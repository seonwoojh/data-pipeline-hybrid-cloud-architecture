## VPC 를 생성한다.

# resource "aws_vpc" "Hybrid_VPC" {
#     cidr_block = ""
#     instance_tenancy = "default"

#     tags = {
#         Name = "Hybrid_VPC"
#     }
# }
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ""

  name = "Hybrid_VPC"
  cidr = ""

  azs                = ["ap-northeast-2a"]
  private_subnets    = [""]
  create_igw         = true
  enable_vpn_gateway = true
}

resource "aws_customer_gateway" "On_premise_cgw" {
  bgp_asn    = 65000
  ip_address = ""
  type       = ""

  tags = {
    Name = "On_premise_cgw"
  }
}

resource "aws_vpn_connection" "aws_vpn_connection" {
  vpn_gateway_id      = module.vpc.vgw_id
  customer_gateway_id = aws_customer_gateway.On_premise_cgw.id
  type                = ""
  static_routes_only  = true

  tags = {
    Name = "SiteToSiteVPN"
  }
}

resource "aws_vpn_connection_route" "vpn_route" {
  count                  = length(var.customer_subnets)
  vpn_connection_id      = aws_vpn_connection.aws_vpn_connection.id
  destination_cidr_block = element(var.customer_subnets, count.index)
}
