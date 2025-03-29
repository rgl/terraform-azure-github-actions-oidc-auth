# syntax=docker.io/docker/dockerfile:1.14

# see https://github.com/Azure/azure-cli/releases
# renovate: datasource=github-releases depName=Azure/azure-cli extractVersion=azure-cli-(?<version>.+)
ARG AZURE_CLI_VERSION='2.70.0'

# see https://github.com/cli/cli/releases
# renovate: datasource=github-releases depName=cli/cli
ARG GITHUB_CLI_VERSION='2.69.0'

# see https://github.com/hashicorp/terraform/releases
# renovate: datasource=github-releases depName=hashicorp/terraform
ARG TERRAFORM_VERSION='1.11.3'

# see https://github.com/devcontainers/images/tree/main/src/base-debian/history
FROM mcr.microsoft.com/devcontainers/base:1.0.20-bookworm

RUN <<'EOF'
#!/usr/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y install --no-install-recommends \
    bash-completion \
    curl \
    python3-argcomplete \
    python3-pip \
    python3-requests \
    python3-venv \
    sudo \
    unzip
apt-get clean
rm -rf /var/lib/apt/lists/*
activate-global-python-argcomplete
python3 -m venv /opt/venv
EOF
ENV PATH="/opt/venv/bin:$PATH"

ARG AZURE_CLI_VERSION
RUN <<'EOF'
#!/usr/bin/bash
set -euxo pipefail
# NB execute apt-cache madison azure-cli to known the available versions.
# see https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt&view=azure-cli-latest
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >/etc/apt/keyrings/packages.microsoft.com.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.com.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
  >/etc/apt/sources.list.d/azure-cli.list
apt-get update
apt-get install -y "azure-cli=$AZURE_CLI_VERSION-*"
apt-get clean
rm -rf /var/lib/apt/lists/*
az --version
EOF

ARG GITHUB_CLI_VERSION
RUN <<'EOF'
#!/usr/bin/bash
set -euxo pipefail
# see https://github.com/cli/cli/blob/trunk/docs/install_linux.md
# see https://github.com/cli/cli/releases
# NB execute apt-cache madison gh to known the available versions.
wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg >/etc/apt/keyrings/cli.github.com.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/cli.github.com.gpg] https://cli.github.com/packages stable main" \
  >/etc/apt/sources.list.d/github-cli.list
apt-get update
apt-get install -y "gh=$GITHUB_CLI_VERSION"
apt-get clean
rm -rf /var/lib/apt/lists/*
az --version
EOF

ARG TERRAFORM_VERSION
ENV CHECKPOINT_DISABLE=1
RUN <<'EOF'
#!/usr/bin/bash
set -euxo pipefail
terraform_url="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
t="$(mktemp -q -d --suffix=.terraform)"
wget -qO "$t/terraform.zip" "$terraform_url"
unzip "$t/terraform.zip" -d "$t"
install "$t/terraform" /usr/local/bin
rm -rf "$t"
terraform -install-autocomplete
EOF

RUN <<'EOF'
#!/usr/bin/bash
set -euxo pipefail
# ensure /etc/profile is called at the top of the file, when running in a
# login shell.
sed -i '0,/esac/s/esac/&\n\nsource \/etc\/profile/' /home/vscode/.bashrc
EOF
COPY inputrc /etc/inputrc
COPY login.sh /etc/profile.d/login.sh

COPY requirements.txt /tmp/pip-tmp/requirements.txt
RUN <<'EOF'
#!/usr/bin/bash
set -euxo pipefail
python -m pip \
    --disable-pip-version-check \
    --no-cache-dir \
    install \
    -r /tmp/pip-tmp/requirements.txt
rm -rf /tmp/pip-tmp
EOF
