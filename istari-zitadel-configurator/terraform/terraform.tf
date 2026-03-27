terraform {
  required_providers {
    zitadel = {
      source  = "zitadel/zitadel"
      version = "2.2.0"
    }
  }

  required_version = ">= 1.9.0"

  backend "local" {
    path = "/terraform/state/terraform.tfstate"
  }
}

provider "zitadel" {
  domain           = var.zitadel_domain
  insecure         = var.zitadel_insecure
  port             = var.zitadel_port
  jwt_profile_json = file(var.sa_json_file)
}
