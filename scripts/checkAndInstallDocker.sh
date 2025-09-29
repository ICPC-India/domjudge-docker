#!/bin/bash

set -euo pipefail

# Check distro is Debian/Ubuntu-like for apt-based install path
is_debian_like() {
    [ -f /etc/debian_version ] || command -v apt-get >/dev/null 2>&1
}

# Function to get the latest Docker version from Docker's official repo
get_latest_docker_version() {
    curl -s https://api.github.com/repos/docker/docker-ce/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^\"]+)".*/\1/' || true
}

# Function to get the installed Docker version
get_installed_docker_version() {
    if command -v docker &> /dev/null; then
        docker --version | awk '{print $3}' | sed 's/,//'
    else
        echo ""
    fi
}

install_or_update_docker() {
    if ! is_debian_like; then
        echo "Automatic installation is only supported for Debian/Ubuntu-like systems. Please install Docker manually." >&2
        return 1
    fi

    echo "Installing/updating Docker... (this may prompt for your password)"

    # Remove old versions if any
    sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

    # Update the apt package index
    sudo apt-get update

    # Install packages to allow apt to use a repository over HTTPS
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    # Add Docker’s official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Set up the stable repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update the apt package index again
    sudo apt-get update

    # Install Docker Engine and components
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Docker installation/update complete."
}

ensure_docker_running() {
    # Try systemd start if Docker daemon is not running
    if ! sudo systemctl is-active --quiet docker 2>/dev/null; then
        echo "Docker daemon is not active. Attempting to start it (requires sudo)..."
        sudo systemctl start docker || true
    fi
}

ensure_group_membership() {
    # Determine current user
    if [ -n "${SUDO_USER:-}" ]; then
        CURUSER="$SUDO_USER"
    elif [ -n "${USER:-}" ]; then
        CURUSER="$USER"
    else
        CURUSER=$(/usr/bin/whoami)
    fi

    # Add to docker group if group exists
    if getent group docker >/dev/null 2>&1; then
        if id -nG "$CURUSER" | grep -qw docker; then
            echo "User $CURUSER is already in the docker group."
        else
            echo "Adding $CURUSER to docker group (requires sudo)..."
            sudo usermod -aG docker "$CURUSER" && echo "Added $CURUSER to docker group." || echo "Failed to add $CURUSER to docker group." >&2
        fi
    else
        echo "docker group not found; it may be created by the Docker package installation." >&2
    fi

    # Ensure sudo group membership for administrative tasks (best-effort)
    if getent group sudo >/dev/null 2>&1; then
        if id -nG "$CURUSER" | grep -qw sudo; then
            echo "User $CURUSER is already in the sudo group."
        else
            echo "Adding $CURUSER to sudo group (requires sudo)..."
            sudo usermod -aG sudo "$CURUSER" && echo "Added $CURUSER to sudo group." || echo "Failed to add $CURUSER to sudo group." >&2
        fi
    else
        echo "sudo group not found on this system." >&2
    fi

    echo "If you were added to the 'docker' or 'sudo' group, you must log out and log back in (or run 'newgrp docker') for the changes to take effect."
}

main() {
    latest_version=$(get_latest_docker_version || true)
    installed_version=$(get_installed_docker_version)

    if [ -n "$installed_version" ] && [ -n "$latest_version" ] && [ "$installed_version" == "$latest_version" ]; then
        echo "Docker is already at the latest version ($latest_version)."
    elif [ -z "$installed_version" ]; then
        echo "Docker is not installed. Proceeding to install."
        install_or_update_docker || true
    else
        echo "Docker version $installed_version is installed; latest known is $latest_version. Proceeding to ensure Docker is up-to-date and running."
        install_or_update_docker || true
    fi

    # After installation attempt, ensure docker command exists and daemon running
    if ! command -v docker >/dev/null 2>&1; then
        echo "Docker binary not found in PATH after installation attempt." >&2
        exit 1
    fi

    ensure_docker_running || true

    # Ensure compose or docker CLI is present
    if ! command -v docker-compose >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1; then
        echo "Neither docker-compose nor docker CLI found after installation." >&2
    fi

    # Ensure the current user is in the docker and sudo groups
    ensure_group_membership
}

main "$@"