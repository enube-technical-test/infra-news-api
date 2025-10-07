terraform {
  backend "s3" {
    bucket = "backend-news-api-tfstate"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}