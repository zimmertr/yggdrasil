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

variables {
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
