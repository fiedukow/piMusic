#!/bin/bash

set -e

log_message() {
  echo "$(date) [$1] $2" | tee -a $LOG_FILE
}

run_safe() {
	set +e
	$@
	RET_CODE=$?
	set -e
	echo $RET_CODE
}

verify_root() {
	if [ $(whoami) != "root" ]; then
		log_message error "Please run this script as root!"
		exit 1
	fi
	log_message info "Verified that script is run as root."
}

disable_swap() {
  log_message info "Disabling swap"
  EXISTS=$(run_safe which dphys-swapfile)
  if [ $EXISTS -ne 0 ]; then
    log_message warning "It seems like swap is already disabled."
		return
  fi

  dphys-swapfile swapoff
  dphys-swapfile uninstall
  update-rc.d dphys-swapfile remove
  apt purge dphys-swapfile
}

update_and_upgrade() {
	log_message info "Updating the OS and installed packages"
	apt-get update
	apt-get upgrade --yes
}

install_essentials() {
	log_message info "Installing essential packages from apt-get"
	apt-get install --yes vim git htop mpd mplayer
}

enable_ssh_server() {
	log_message info "Enabling SSH access to the raspberry pi"
	systemctl enable ssh
	systemctl start ssh
}

# Main portion of the script
mkdir -p logs
LOG_FILE="logs/piMusic-install.$(date +%Y-%m-%d_%H.%M.%S).log"
log_message info "Starting installation of piMusic"
log_message info "Will log to $LOG_FILE"

verify_root
disable_swap
update_and_upgrade
install_essentials
enable_ssh_server

log_message info "Installation complete!"

