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

# Environment variables for staging
variable "staging_env_vars" {
  description = "Environment variables for staging environment"
  type        = map(string)
  default     = {}
}

# Environment variables for production
variable "prod_env_vars" {
  description = "Environment variables for production environment"
  type        = map(string)
  default     = {}
}