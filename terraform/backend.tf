terraform {
  backend "s3" {
    bucket  = "up42-challenge-terraform-state-cb39643c3b736d17"
    key     = "terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}
