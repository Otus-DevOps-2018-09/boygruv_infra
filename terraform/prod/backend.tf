terraform {
  backend "gcs" {
    bucket  = "boygruv-tf-state-prod"
    prefix  = "terraform/state"
  }
}
