variable "environment" {}
variable "project_name" {}

resource "aws_dynamodb_table" "products" {
  name         = "${var.project_name}-products-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-products"
    Environment = var.environment
  }
}

output "table_name" {
  value = aws_dynamodb_table.products.name
}
