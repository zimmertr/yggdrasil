variable "github_tokens" {
  description = "One zimmertr-yggdrasil-bot installation token per owner, keyed by owner, minted by the workflow for each run (#8, step 6.5)."
  type        = map(string)
  sensitive   = true
}

variable "repos_dir" {
  description = "The folder of repo files. Tests point it at their fixtures."
  type        = string
  default     = "../../repos"
}
