# AWS Secrets Manager secrets for staging
resource "aws_secretsmanager_secret" "staging_secrets" {
  name                    = "SttfApiStagingContainerSecrets"
  description             = "Environment variables for STTF backend staging container"
  recovery_window_in_days = 7

  tags = {
    Name        = "sttf-backend-staging-secrets"
    Environment = "staging"
    Project     = "sttf-hosting"
  }
}

# AWS Secrets Manager secret version for staging
resource "aws_secretsmanager_secret_version" "staging_secrets" {
  secret_id = aws_secretsmanager_secret.staging_secrets.id
  secret_string = jsonencode({
    # Database configuration (PostgreSQL)
    POSTGRES_HOST     = split(":", aws_db_instance.sttf_api_staging_db.endpoint)[0]
    POSTGRES_PORT     = aws_db_instance.sttf_api_staging_db.port
    POSTGRES_DB       = "postgres"
    POSTGRES_USER     = "sttf_admin"
    POSTGRES_PASSWORD = var.staging_db_password

    # Environment
    NODE_ENV    = "staging"
    ENVIRONMENT = "staging"

    # Environment variables from terraform.tfvars
    APP_PORT       = tostring(var.staging_env_vars.APP_PORT)
    ENCRYPTION_KEY = var.staging_env_vars.ENCRYPTION_KEY
    SESSION_SECRET = var.staging_env_vars.SESSION_SECRET

    # Sentry
    SENTRY_DSN = var.staging_env_vars.SENTRY_DSN

    # Frontend
    WEB_FRONTEND_URL    = var.staging_env_vars.WEB_FRONTEND_URL
    MOBILE_FRONTEND_URL = var.staging_env_vars.MOBILE_FRONTEND_URL

    # Firebase config
    FIREBASE_API_KEY             = var.staging_env_vars.FIREBASE_API_KEY
    FIREBASE_AUTH_DOMAIN         = var.staging_env_vars.FIREBASE_AUTH_DOMAIN
    FIREBASE_PROJECT_ID          = var.staging_env_vars.FIREBASE_PROJECT_ID
    FIREBASE_STORAGE_BUCKET      = var.staging_env_vars.FIREBASE_STORAGE_BUCKET
    FIREBASE_MESSAGING_SENDER_ID = var.staging_env_vars.FIREBASE_MESSAGING_SENDER_ID
    FIREBASE_APP_ID              = var.staging_env_vars.FIREBASE_APP_ID
    FIREBASE_CLIENT_EMAIL        = var.staging_env_vars.FIREBASE_CLIENT_EMAIL
    FIREBASE_PRIVATE_KEY         = jsonencode(var.staging_env_vars.FIREBASE_PRIVATE_KEY)

    # Whoop config
    WHOOP_CLIENT_ID     = var.staging_env_vars.WHOOP_CLIENT_ID
    WHOOP_CLIENT_SECRET = var.staging_env_vars.WHOOP_CLIENT_SECRET
    WHOOP_AUTHORIZE_URL = var.staging_env_vars.WHOOP_AUTHORIZE_URL
    WHOOP_TOKEN_URL     = var.staging_env_vars.WHOOP_TOKEN_URL
  })
}

# AWS Secrets Manager secrets for production
resource "aws_secretsmanager_secret" "prod_secrets" {
  name                    = "SttfApiProdContainerSecrets"
  description             = "Environment variables for STTF backend production container"
  recovery_window_in_days = 7

  tags = {
    Name        = "sttf-backend-prod-secrets"
    Environment = "production"
    Project     = "sttf-hosting"
  }
}

# AWS Secrets Manager secret version for production
resource "aws_secretsmanager_secret_version" "prod_secrets" {
  secret_id = aws_secretsmanager_secret.prod_secrets.id
  secret_string = jsonencode({
    # Database configuration (PostgreSQL)
    POSTGRES_HOST     = split(":", aws_db_instance.sttf_api_prod_db.endpoint)[0]
    POSTGRES_PORT     = aws_db_instance.sttf_api_prod_db.port
    POSTGRES_DB       = "postgres"
    POSTGRES_USER     = "sttf_admin"
    POSTGRES_PASSWORD = var.prod_db_password

    # Environment
    NODE_ENV    = "production"
    ENVIRONMENT = "production"

    # Environment variables from terraform.tfvars
    APP_PORT       = tostring(var.prod_env_vars.APP_PORT)
    ENCRYPTION_KEY = var.prod_env_vars.ENCRYPTION_KEY
    SESSION_SECRET = var.prod_env_vars.SESSION_SECRET

    # Sentry
    SENTRY_DSN = var.prod_env_vars.SENTRY_DSN

    # Frontend
    WEB_FRONTEND_URL    = var.prod_env_vars.WEB_FRONTEND_URL
    MOBILE_FRONTEND_URL = var.prod_env_vars.MOBILE_FRONTEND_URL

    # Firebase config
    FIREBASE_API_KEY             = var.prod_env_vars.FIREBASE_API_KEY
    FIREBASE_AUTH_DOMAIN         = var.prod_env_vars.FIREBASE_AUTH_DOMAIN
    FIREBASE_PROJECT_ID          = var.prod_env_vars.FIREBASE_PROJECT_ID
    FIREBASE_STORAGE_BUCKET      = var.prod_env_vars.FIREBASE_STORAGE_BUCKET
    FIREBASE_MESSAGING_SENDER_ID = var.prod_env_vars.FIREBASE_MESSAGING_SENDER_ID
    FIREBASE_APP_ID              = var.prod_env_vars.FIREBASE_APP_ID
    FIREBASE_CLIENT_EMAIL        = var.prod_env_vars.FIREBASE_CLIENT_EMAIL
    FIREBASE_PRIVATE_KEY         = jsonencode(var.prod_env_vars.FIREBASE_PRIVATE_KEY)

    # Whoop config
    WHOOP_CLIENT_ID     = var.prod_env_vars.WHOOP_CLIENT_ID
    WHOOP_CLIENT_SECRET = var.prod_env_vars.WHOOP_CLIENT_SECRET
    WHOOP_AUTHORIZE_URL = var.prod_env_vars.WHOOP_AUTHORIZE_URL
    WHOOP_TOKEN_URL     = var.prod_env_vars.WHOOP_TOKEN_URL
  })
}
