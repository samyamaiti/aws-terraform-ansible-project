terraform {
  backend "s3" {
    region = "us-west-2"
    # Other settings will be provided via backend-config in terraform init
  }
}
