terraform {
  required_version = "1.11.3"
  required_providers {
    # see https://registry.terraform.io/providers/hashicorp/azurerm
    # see https://github.com/hashicorp/terraform-provider-azurerm
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.25.0"
    }
    # see https://registry.terraform.io/providers/integrations/github
    # see https://github.com/integrations/terraform-provider-github
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
  }
}

provider "azurerm" {
  features {
  }
}

provider "github" {
}

variable "github_repository_url" {
  type        = string
  description = "GitHub repository URL in format git@github.com:owner/repo.git or https://github.com/owner/repo"
  default     = "git@github.com:rgl/terraform-azure-github-actions-oidc-auth.git"
  validation {
    condition     = can(regex("^(git@github.com:|https://github.com/)[^/]+/[^/]+", var.github_repository_url))
    error_message = "Must be a valid GitHub URL: git@github.com:owner/repo.git or https://github.com/owner/repo"
  }
}
# NB you can test the relative speed from you browser to a location using https://azurespeedtest.azurewebsites.net/
# get the available locations with: az account list-locations --output table
variable "location" {
  type        = string
  description = "Azure region to deploy resources"
  default     = "France Central" # see https://azure.microsoft.com/en-us/global-infrastructure/france/
}

variable "name_prefix" {
  type        = string
  description = "Prefix for all Azure resources"
  default     = "rgl-gha-oidc"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "Prefix must be lowercase alphanumeric characters or hyphens"
  }
}

locals {
  github_owner = regex("github.com[:/]([^/]+)", var.github_repository_url)[0]
  github_repo  = regex("github.com[:/][^/]+/([^/.]+)", var.github_repository_url)[0]

  resource_group_name = "${var.name_prefix}-${local.github_owner}-${local.github_repo}"
  identity_name       = "${var.name_prefix}-${local.github_owner}-${local.github_repo}"
}

# see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config
data "azurerm_client_config" "current" {
}

data "azurerm_subscription" "current" {
}

# see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
resource "azurerm_resource_group" "github" {
  name     = local.resource_group_name
  location = var.location
}

# see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity
resource "azurerm_user_assigned_identity" "github" {
  name                = local.identity_name
  resource_group_name = azurerm_resource_group.github.name
  location            = azurerm_resource_group.github.location
}

# see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential
resource "azurerm_federated_identity_credential" "github_main_branch" {
  name                = "${local.identity_name}-main"
  resource_group_name = azurerm_resource_group.github.name
  parent_id           = azurerm_user_assigned_identity.github.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${local.github_owner}/${local.github_repo}:ref:refs/heads/main"
}

# see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential
resource "azurerm_federated_identity_credential" "github_wip_branch" {
  name                = "${local.identity_name}-wip"
  resource_group_name = azurerm_resource_group.github.name
  parent_id           = azurerm_user_assigned_identity.github.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${local.github_owner}/${local.github_repo}:ref:refs/heads/wip"
}

# see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment
resource "azurerm_role_assignment" "github" {
  scope                = data.azurerm_subscription.current.id
  principal_id         = azurerm_user_assigned_identity.github.principal_id
  role_definition_name = "Reader"
}

# see https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable
resource "github_actions_variable" "azure" {
  for_each = {
    AZURE_CLIENT_ID       = azurerm_user_assigned_identity.github.client_id
    AZURE_TENANT_ID       = data.azurerm_client_config.current.tenant_id
    AZURE_SUBSCRIPTION_ID = data.azurerm_client_config.current.subscription_id
  }
  repository    = local.github_repo
  variable_name = each.key
  value         = each.value
}
