terraform {
  backend "s3" {
    bucket         = "terraform-ansible-project-state"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
