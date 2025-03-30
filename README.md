# About

[![Build](https://github.com/rgl/terraform-azure-github-actions-oidc-auth/actions/workflows/build.yml/badge.svg)](https://github.com/rgl/terraform-azure-github-actions-oidc-auth/actions/workflows/build.yml)

Terraform example that configures an authentication federation between Microsoft Entra ID and GitHub Actions OIDC.

This lets us use Azure from a GitHub Actions Workflow Job without using static secrets.

It uses the GitHub Actions Workflow Job OIDC ID Token to authenticate in Azure.

This will:

* Configure Microsoft Entra ID.
  * Create the GitHub Actions OIDC Federation.
  * Create a User-Assigned Managed Identity to represent the GitHub Actions Workflow Identity.
    * This identity will have `Reader` permissions in the entire Azure subscription.
* Configure GitHub Repository.
  * Add the Azure related environment variables as GitHub Actions Variables.
    * Please note that these values are not sensitive to me, as such, they are not saved as GitHub Actions Secrets, but YMMV.
* Show the [Build GitHub Actions Workflow](https://github.com/rgl/terraform-azure-github-actions-oidc-auth/actions/workflows/build.yml).
  * It has two example jobs:
    1. `build-with-azure-cli`: Login into Azure using the [azure/login action](https://github.com/Azure/login), then use the Azure CLI to interact with Azure.
    2. `build-with-curl`: Use `curl` to request a GitHub Actions OIDC ID Token, exchange it for an Azure Access Token, then interact with Azure.

# Usage

Install the dependencies:

* [Visual Studio Code](https://code.visualstudio.com).
* [Dev Container plugin](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

Open this directory with the Dev Container plugin.

Open the Visual Studio Code Terminal.

Login into Azure:

```bash
az login

# list the subscriptions.
az account list --all
az account show

# set the subscription.
export ARM_SUBSCRIPTION_ID="<YOUR-SUBSCRIPTION-ID>"
az account set --subscription "$ARM_SUBSCRIPTION_ID"
az account show
```

Login into GitHub:

```bash
gh auth login
gh auth status
```

Provision the azure infrastructure:

```bash
export CHECKPOINT_DISABLE=1
export TF_LOG=INFO # ERROR, WARN, INFO, DEBUG, TRACE.
export TF_LOG_PATH=terraform.log
rm -f "$TF_LOG_PATH"
terraform init
terraform apply
```

Manually trigger the [Build GitHub Actions Workflow](https://github.com/rgl/terraform-azure-github-actions-oidc-auth/actions/workflows/build.yml) execution and watch it use Azure without using any static secret.

When you are done, destroy everything:

```bash
terraform destroy
```

List this repository dependencies (and which have newer versions):

```bash
GITHUB_COM_TOKEN='YOUR_GITHUB_PERSONAL_TOKEN' ./renovate.sh
```

# References

* [Azure: Login With OpenID Connect (OIDC)](https://github.com/azure/login?tab=readme-ov-file#login-with-openid-connect-oidc-recommended).
* [Azure: Managed identities](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/).
* [GitHub: About security hardening with OpenID Connect](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect).
* [GitHub: Variables](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/store-information-in-variables).
* [GitHub: Secrets](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions).
