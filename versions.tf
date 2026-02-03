terraform {
  required_version = ">= 1.0.0"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "5.6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
