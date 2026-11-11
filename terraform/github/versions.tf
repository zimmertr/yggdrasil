# The github stack: TJ's repos and orgs on GitHub (#8). This file pins
# Terraform and the providers; main.tf and orgs.tf call the modules.
terraform {
  required_version = "~> 1.17"

  # State and locks in HCP Terraform, in local execution mode: plans and
  # applies run in Actions (decision record 0008). The checks run
  # `terraform init -backend=false`, which skips this block.
  cloud {
    # Terraform's own default, named because dflook's init fails without it.
    hostname     = "app.terraform.io"
    organization = "Yggdrasil-Org"

    workspaces {
      name = "github"
    }
  }

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
    # The three settings integrations/github lacks (decision record 0024).
    restapi = {
      source  = "Mastercard/restapi"
      version = "~> 3.0"
    }
  }
}
