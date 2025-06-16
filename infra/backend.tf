terraform {
  backend "s3" {
    bucket         = "[bucket_id_here]"
    key            = "rds/dev/rds-postgres-terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}