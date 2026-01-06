terraform {
  required_providers {
    coderd = {
      source  = "coder/coderd"
      version = "~> 1.0"
    }
  }
}

provider "coderd" {
  url = var.coder_url
  # Token is provided via CODER_TOKEN environment variable
}

variable "coder_url" {
  description = "URL of the Coder deployment"
  type        = string
}

variable "template_name" {
  description = "Name of the template"
  type        = string
  default     = "bmad-vscode"
}

variable "template_version" {
  description = "Version of the template"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for workspaces"
  type        = string
}

variable "use_kubeconfig" {
  description = "Use host kubeconfig"
  type        = bool
  default     = false
}

variable "bmad_cli_version" {
  description = "BMAD CLI version"
  type        = string
  default     = "latest"
}

# Create or update the template
resource "coderd_template" "bmad_vscode" {
  name         = var.template_name
  description  = "BMAD Development Environment with VS Code"
  display_name = "BMAD VS Code Workspace"
  icon         = "/icon/k8s.png"

  # The provider requires a versions attribute; template versions are
  # managed via coderd_template_version resource, so provide an empty list here.
  versions = []

  default_ttl_ms                 = 0
  activity_bump_ms               = 0
  # auto-stop / user start/stop options are not supported on this resource
  # in this provider version and should be configured elsewhere if needed.
  failure_ttl_ms                 = 0
  time_til_dormant_ms            = 0
  time_til_dormant_autodelete_ms = 0
}

# Create a new version of the template
resource "coderd_template_version" "bmad_vscode_version" {
  template_id = coderd_template.bmad_vscode.id
  directory   = "${path.module}/.."
  name        = var.template_version
  message     = "Automated deployment via GitHub Actions - v${var.template_version}"
  
  tf_vars = [
    {
      name  = "use_kubeconfig"
      value = tostring(var.use_kubeconfig)
    },
    {
      name  = "namespace"
      value = var.namespace
    },
    {
      name  = "bmad_cli_version"
      value = var.bmad_cli_version
    }
  ]
}

# Set the active version
resource "coderd_template_version_active" "bmad_vscode_active" {
  template_id         = coderd_template.bmad_vscode.id
  template_version_id = coderd_template_version.bmad_vscode_version.id
}

output "template_id" {
  description = "The ID of the template"
  value       = coderd_template.bmad_vscode.id
}

output "template_version_id" {
  description = "The ID of the template version"
  value       = coderd_template_version.bmad_vscode_version.id
}

output "template_version_name" {
  description = "The name of the template version"
  value       = coderd_template_version.bmad_vscode_version.name
}
