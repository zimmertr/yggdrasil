# Only the org's profile and billing email: every other setting is the same on
# every org, set in main.tf (decision record 0051). The defaults live once, in
# the github stack's local.org_defaults, which also decides which keys a file
# may use.
variable "settings" {
  description = "The org's file merged over the stack's defaults."
  type = object({
    billing_email    = string
    name             = string
    description      = string
    blog             = string
    email            = string
    location         = string
    company          = string
    twitter_username = string
  })
}
