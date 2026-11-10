output "name" {
  description = "The org's display name, for the stack's tests."
  value       = github_organization_settings.this.name
}

output "billing_email" {
  description = "The org's billing email, for the stack's tests."
  value       = github_organization_settings.this.billing_email
}
