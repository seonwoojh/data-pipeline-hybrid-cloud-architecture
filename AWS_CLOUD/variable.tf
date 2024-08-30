variable "region" {
  type        = string
  description = "aws 리전"
  default     = "ap-northeast-2"
}

variable "customer_subnets" {
  type    = list(string)
  default = ["Insert Configuration"]
}

variable "access_key" {
  type        = string
  description = "Enter access_key"
  default     = ""
}

variable "secret_key" {
  type        = string
  description = "Enter secret_key"
  default     = ""
}
