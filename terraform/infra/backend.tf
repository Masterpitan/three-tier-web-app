terraform {
  backend "s3" {
    bucket = "practical-devops-file-state"
    dynamodb_table = "state-lock"
    key = "terraform/infra.tfstate"
    region = "us-west-2"
    encrypt = true
  }
}
