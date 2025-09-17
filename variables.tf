variable "staging_db_password" {
  description = "Password for the staging database"
  type        = string
  sensitive   = true
}

variable "prod_db_password" {
  description = "Password for the production database"
  type        = string
  sensitive   = true
}

variable "key_pair_name" {
  description = "Name of the AWS key pair to use for EC2 instances"
  type        = string
}