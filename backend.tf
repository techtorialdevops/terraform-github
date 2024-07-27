terraform {
  backend "s3" {
    bucket = "tuncay-terraform6"
    key    = "terraform.tfstate"
    region = "us-east-2"
  }
}