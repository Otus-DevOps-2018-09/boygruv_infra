terraform {
  backend "gcs" {
    bucket  = "boygruv-tf-state-stage"
    prefix  = "terraform/state"
  }
}
