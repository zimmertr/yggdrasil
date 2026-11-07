variable "owner" {
  description = "The account or org that owns the repo, from its folder under repos/."
  type        = string
}

variable "name" {
  description = "The repo's name, from its file name under repos/<owner>/."
  type        = string
}

# Only what may differ between repos, and nothing that is a security setting:
# the module turns every security feature on for every repo GitHub allows it
# on, so a repo file has no way to turn one off (decision record 0043). The
# defaults live once, in the github stack's local.defaults, which also decides
# which keys a file may use.
variable "settings" {
  description = "The repo's file merged over the stack's defaults."
  type = object({
    description     = string
    homepage_url    = string
    topics          = list(string)
    visibility      = string
    archived        = bool
    is_template     = bool
    required_checks = list(string)
  })

  validation {
    condition     = contains(["public", "private"], var.settings.visibility)
    error_message = "visibility is public or private."
  }
}
