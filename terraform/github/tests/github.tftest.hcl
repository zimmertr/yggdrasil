# The github stack on mock providers: how it reads repos/, and the two kinds
# of file it refuses. Decision record 0043.

mock_provider "github" {
  alias = "zimmertr"
}
mock_provider "github" {
  alias = "bluebird_forecast"
}
mock_provider "github" {
  alias = "fellfield_game"
}
mock_provider "github" {
  alias = "gpx_search"
}
mock_provider "github" {
  alias = "tjs_kubernetes_service"
}
mock_provider "github" {
  alias = "lakebagger"
}
mock_provider "restapi" {
  alias = "zimmertr"
}
mock_provider "restapi" {
  alias = "bluebird_forecast"
}
mock_provider "restapi" {
  alias = "fellfield_game"
}
mock_provider "restapi" {
  alias = "gpx_search"
}
mock_provider "restapi" {
  alias = "tjs_kubernetes_service"
}
mock_provider "restapi" {
  alias = "lakebagger"
}

# The good fixture's zimmertr/.github is imported (imports.tf), and a mock
# provider can't import, so the test supplies that one resource itself.
override_resource {
  target = module.zimmertr[".github"].github_repository.this
}

# The org fixture's Lakebagger is imported too.
override_resource {
  target = module.lakebagger_org[0].github_organization_settings.this
}

variables {
  orgs_dir = "tests/fixtures/orgs-good"

  github_tokens = {
    "zimmertr"               = "test"
    "Bluebird-Forecast"      = "test"
    "Fellfield-Game"         = "test"
    "GPX-Search"             = "test"
    "TJs-Kubernetes-Service" = "test"
    "Lakebagger"             = "test"
  }
}

run "reads_each_file_under_its_owner" {
  command = plan

  variables {
    repos_dir = "tests/fixtures/good"
  }

  assert {
    condition     = output.repos == tolist(["zimmertr/.github", "zimmertr/example"])
    error_message = "Each repos/<owner>/<name>.yml is one repo, .github included."
  }

  assert {
    condition = (
      toset(keys(module.zimmertr)) == toset([".github", "example"]) &&
      length(module.bluebird_forecast) == 0
    )
    error_message = "A file reaches only its own owner's module."
  }
}

run "refuses_an_unknown_key" {
  command = plan

  variables {
    repos_dir = "tests/fixtures/unknown-key"
  }

  expect_failures = [output.repos]
}

run "refuses_an_unknown_owner" {
  command = plan

  variables {
    repos_dir = "tests/fixtures/unknown-owner"
  }

  expect_failures = [output.repos]
}

run "reads_each_org_file" {
  command = plan

  variables {
    repos_dir = "tests/fixtures/good"
  }

  assert {
    condition = (
      output.orgs == tolist(["Lakebagger"]) &&
      length(module.lakebagger_org) == 1 &&
      length(module.bluebird_forecast_org) == 0
    )
    error_message = "Each orgs/<name>.yml is one org, and reaches only that org's module."
  }

  assert {
    condition = (
      module.lakebagger_org[0].name == "Lakebagger" &&
      module.lakebagger_org[0].billing_email == "tj@tjzimmerman.com"
    )
    error_message = "An org file's keys merge over the defaults."
  }
}

run "refuses_an_unknown_org_key" {
  command = plan

  variables {
    repos_dir = "tests/fixtures/good"
    orgs_dir  = "tests/fixtures/orgs-unknown-key"
  }

  expect_failures = [output.orgs]
}
