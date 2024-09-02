# # VPN 연결 구성을 Local file로 저장한다.
resource "local_file" "vpn_config" {
  content = aws_vpn_connection.SiteToSiteVPN.customer_gateway_configuration
  ### 안에 세부 옵션들 확인 ex ikev1
  filename = "Insert Configuration"
}

## DB연결 정보 저장
resource "local_file" "db_config" {
  content  = random_password.db_password.result
  filename = "Insert Configuration"
}