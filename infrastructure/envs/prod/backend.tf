terraform {
  backend "s3" {
    bucket = "online-boutique-tfstate-767397659229"
    key    = "online-boutique/dev/terraform.tfstate"
    region = "us-east-1"
    #dynamodb_table = "online-boutique-tf-lock"
    use_lockfile = true
    encrypt      = true
  }
}