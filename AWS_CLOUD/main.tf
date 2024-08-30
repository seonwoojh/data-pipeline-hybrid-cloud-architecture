############################################################################################
## VPC 모듈을 통해 VPC, Subnet, Security_group, VGW를 생성한다.

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = "Hybrid_VPC"
  cidr = "Insert Configuration"

  azs                                = ["ap-northeast-2a"]      # 가용영역 설정
  private_subnets                    = ["Insert Configuration"] # 서브넷 설정
  create_igw                         = false                    # IGW 비활성화
  enable_vpn_gateway                 = true                     # AWS VGW 생성
  manage_default_network_acl         = false                    # ACL 비활성화
  propagate_private_route_tables_vgw = true                     # 라우팅 전파 활성화

  ### Security_group 설정
  default_security_group_name = "vpn_security_group"

  ## Inbound Setting
  default_security_group_ingress = [
    {
      description = "vpn_security_group"
      cidr_blocks = "Insert Configuration"
      from_port   = "Insert Configuration"
      to_port     = "Insert Configuration"
      protocol    = "Insert Configuration"
    }
  ]
  ## Outbound Setting
  default_security_group_egress = [
    {
      cidr_blocks = "0.0.0.0/0"
      protocol    = "-1" # semantically equivalent to all ports
    }
  ]
}

############################################################################################
## On-premise Network의 CGW를 생성한다.(고객 게이트웨이)
resource "aws_customer_gateway" "On_premise_cgw" {
  bgp_asn    = 65000
  ip_address = "Insert Configuration"
  type       = "Insert Configuration"

  tags = {
    Name = "On_premise_cgw"
  }
}

## Site to Site VPN을 생성한다.
resource "aws_vpn_connection" "SiteToSiteVPN" {
  vpn_gateway_id      = module.vpc.vgw_id
  customer_gateway_id = aws_customer_gateway.On_premise_cgw.id
  type                = aws_customer_gateway.On_premise_cgw.type
  static_routes_only  = true

  #   ## 터널 1 설정 --- 권한 필요
  #   tunnel1_log_options {
  #     cloudwatch_log_options {
  #       log_enabled = true
  #       log_output_format = "json"
  #     }
  #   }
  # #   tunnel1_phase1_encryption_algorithms = 



  #   tunnel2_log_options {
  #     cloudwatch_log_options {
  #       log_enabled = true
  #       log_output_format = "json"
  #     }
  #   }

  #   # tunnel2_phase1_encryption_algorithms = 

  depends_on = [aws_customer_gateway.On_premise_cgw]

  tags = {
    Name = "SiteToSiteVPN"
  }
}
### S2S VPN에 Static Routing 경로를 설정한다.
resource "aws_vpn_connection_route" "vpn_route" {
  count                  = length(var.customer_subnets)
  vpn_connection_id      = aws_vpn_connection.SiteToSiteVPN.id
  destination_cidr_block = element(var.customer_subnets, count.index)
}

# # VPN 연결 구성을 Local file로 저장한다.
resource "local_file" "vpn_config" {
  content = aws_vpn_connection.SiteToSiteVPN.customer_gateway_configuration
  ### 안에 세부 옵션들 확인 ex ikev1
  filename = "Insert Configuration"
}

