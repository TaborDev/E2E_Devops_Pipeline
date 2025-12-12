provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true
  access_key                  = "test"
  secret_key                  = "test"

  endpoints {
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
  }
}

module "dynamodb" {
  source       = "./modules/dynamodb"
  environment  = "dev"
  project_name = "techcommerce"
}

# Output the existing S3 bucket name
output "s3_bucket_name" {
  value = "techcommerce-dev-orders"
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}
