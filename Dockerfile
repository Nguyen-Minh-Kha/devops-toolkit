# Use the latest Debian image as the base
FROM debian:12

# Set environment variable to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set Architecture - needed for some downloads/repos
ARG TARGETARCH=amd64

# Install prerequisites, core tools, systemd, pipewire libs, python venv, and cleanup apt cache
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # Prerequisites for other tools
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common \
    # Core requested tools available via apt
    git \
    python3 \
    python3-pip \
    python3.11-venv \
    awscli \
    ansible \
    # Systemd related packages (see note about running systemd in Docker)
    systemd \
    libpam-systemd \
    # Pipewire client libraries (Corrected package name)
    libpipewire-0.3-0 \
    neofetch \
    vi \
    && \
    # --- Clean up apt ---
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# --- Install Azure CLI ---
# Ref: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt
# Note: The Azure CLI script might run apt-get update/install itself.
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
    # --- Clean up apt potentially used by script ---
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# --- Install Terraform ---
# Ref: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
# 1. Install the HashiCorp GPG key
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
# 2. Add the HashiCorp repository
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg arch=${TARGETARCH}] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
# 3. Update apt package index and install Terraform
RUN apt-get update && \
    apt-get install -y terraform && \
    # --- Clean up apt ---
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# --- Install kubectl ---
# Ref: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
# Download latest stable version
RUN KUBECTL_LATEST_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_LATEST_VERSION}/bin/linux/${TARGETARCH}/kubectl" && \
    # Install kubectl
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    # Clean up downloaded file
    rm kubectl

# --- Install Helm ---
# Ref: https://helm.sh/docs/intro/install/#from-script
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Set a default command (e.g., open a bash shell)
CMD ["/bin/bash"]