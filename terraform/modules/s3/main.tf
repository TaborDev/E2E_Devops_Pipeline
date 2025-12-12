variable "environment" {}
variable "project_name" {}

# Use a data source to reference the existing bucket
data "aws_s3_bucket" "existing" {
  bucket = "techcommerce-dev-orders"
}

output "bucket_name" {
  value = data.aws_s3_bucket.existing.id
}
