# TODO: Re-enable staging when needed
# variable "staging_db_password" {
#   description = "Password for the staging database"
#   type        = string
#   sensitive   = true
# }

variable "prod_db_password" {
  description = "Password for the production database"
  type        = string
  sensitive   = true
}

variable "key_pair_name" {
  description = "Name of the AWS key pair to use for EC2 instances"
  type        = string
}

# TODO: Re-enable staging when needed
# Environment variables for staging
# variable "staging_env_vars" {
#   description = "Environment variables for staging environment"
#   type        = map(string)
#   default     = {}
# }

# Environment variables for production
variable "prod_env_vars" {
  description = "Environment variables for production environment"
  type        = map(string)
  default     = {}
}

# Domain configuration
variable "domain_name" {
  description = "Domain name for the API (e.g., api.example.com). Leave empty to use ALB DNS name only."
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID (leave empty to create a new one)"
  type        = string
  default     = ""
}

variable "create_route53_zone" {
  description = "Whether to create a new Route53 hosted zone"
  type        = bool
  default     = false
}

# SSL certificate configuration
variable "ssl_certificate" {
  description = "SSL certificate content (cert.pem)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssl_private_key" {
  description = "SSL private key content (key.pem)"
  type        = string
  sensitive   = true
  default     = ""
}