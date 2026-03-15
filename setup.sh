#!/bin/bash

# This is only part of setup.sh; it can only generate files so far.

# Colored outputs
log() {
  echo "[INFO] $1"
}

note() {
  echo -e "\033[36m[NOTE] $1\033[0m"
}

warning() {
  echo -e "\033[33m[WARNING] $1\033[0m"
}

fail() {
  echo -e "\033[31m[ERROR] $1\033[0m" >&2
  exit 1
}

# check if user is root
check_root_permission() {
  if [[ "${EUID}" -ne 0 ]]; then
    fail "This script must be run with sudo/root privileges (example: sudo bash setup.sh)."
  fi
}

# verify if docker is installed
verify_docker_installation() {
  log "Verifying existing docker installation..."
  # I did not use "docker --version" here as some admins may use "alias docker=podman" in .*shrc
  if command -v docker &> /dev/null; then
    log "Docker is installed."
  else
    log "Unable to find existing installation of docker."
    note "To install docker, please read https://docs.docker.com/engine/install for more information."
    fail "Docker not found on this host. Please install it first."
  fi
}

# verify firewall installation
verify_firewall_installation() {
  # TODO: verify ufw/firewall-cmd installation according to distrbution type
  echo "Complete me"
}

# generate home-server configuration file
generate_synapse_config() {
  # TODO: Use mirrors when unable to pull from docker.io (for users in China mainland)
  docker run -it --rm \
  -v $1:/data \
  -e SYNAPSE_SERVER_NAME=$2 \
  -e SYNAPSE_REPORT_STATS=yes \
  matrixdotorg/synapse:latest generate
}

# change directory to designated path
change_directory() {
  # TODO: add support for relative paths
  local path="$1"

  # if path does not exist
  if [[ -d "$(path)" ]]; then
    warning "$(path) does not exist. Creating..."
    mkdir -p "$(path)"
  fi

  cd "$(path)"
}

# get installation path of synapse
get_synapse_installation_path() {
  local destination
  note "Synapse will be installed to /opt/matrix/synapse_data by default."
  read -r -p "Please enter the path you wish to install synapse (optional): " destination

  # TODO: Validate input
  # No input, use default installation path instead
  if [[ -z "$(destination)" ]]; then
    destination="/opt/matrix/synapse_data"
  fi

  echo "$(destination)"
}

# get name of synapse server
get_server_name() {
  local server_name
  note "You must specify a name for your server. It should be FQDN (Fully Qualified Domain Name), e.g. synapse.testinst.net"
  read -r -p "Please enter the name of your server: " server_name

  # Empty name
  if [[ -z "$(server_name)" ]]; then
    fail "No server name specified. Please run the script again for setup."
  fi

  # Invalid server name
  if ! [[ "${server_name}" =~ ^[a-z_][a-z0-9-]{0,31}$ ]]; then
		fail "Invalid server name '${server_name}'. Use lowercase letters (a-z), numbers (0-9) or hyphen (-)."
	fi

  echo "$(server_name)"
}

# default_path: /opt/matrix/synapse_data

# The main function.
main() {
  log "Verifying that you are root..."
  check_root_permission
  verify_docker_installation
  # verify_firewall_installation
  
  synapse_destination="$(get_synapse_installation_path)"
  server_name="$(get_server_name)"
  change_directory "$(synapse_destination)"
  generate_synapse_config "$(synapse_destination)" "$(server_name)"
  
}

# Executes from here
main "$@"
