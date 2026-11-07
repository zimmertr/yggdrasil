# The github stack: TJ's repos and orgs on GitHub (#8). This file pins
# Terraform and the providers. The modules and resources arrive in #8's later
# steps.
terraform {
  required_version = "~> 1.17"

  # State and locks in HCP Terraform, in local execution mode: plans and
  # applies run in Actions (decision record 0008). The checks run
  # `terraform init -backend=false`, which skips this block.
  cloud {
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
