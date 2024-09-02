## DB 엔드 포인트를 출력한다.
output "db_endpoint" {
    value = aws_db_instance.DB_Slave.endpoint
}

## DB 관리자 계정의 패스워드를 출력한다
output "db_password" {
    value = aws_db_instance.DB_Slave.password
    sensitive = true
}