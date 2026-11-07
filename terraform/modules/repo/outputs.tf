output "full_name" {
  description = "owner/name, for the stack's own outputs and tests."
  value       = github_repository.this.full_name
}
