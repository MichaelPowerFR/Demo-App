terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "vault-demo-s3-state-backend-paris"
    key            = "terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "terraform-state-lock-dynamo"
  }
}
