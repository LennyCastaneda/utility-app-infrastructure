/******************************************************************************
* DYNAMO DB
*******************************************************************************/

resource "aws_dynamodb_table" "utility_app" {
  name           = join("-",["${var.name}", "db"])
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "UserId"
  range_key      = "Utility-Statement"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "Utility-Statement"
    type = "S"
  }

  attribute {
    name = "Billing"
    type = "N"
  }

  global_secondary_index {
    name               = "Utility-StatementIndex"
    hash_key           = "Utility-Statement"
    range_key          = "Billing"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["UserId"]
  }

  tags = {
    Name        = join("-",["${var.name}", "db"])
    Environment = "development"
  }
}