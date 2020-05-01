provider "google" {
  version = "~> 3.16.0"
}
provider "google-beta" {
  version = "~> 3.17.0"
}

data "google_billing_account" "bills" {
  billing_account = var.billing
  open         = true
}
 




