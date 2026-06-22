terraform {
  backend "s3" {
    bucket         = "terraform-state-demo-unique"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}