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

collect_input() {
	PI_MUSIC_VARS_FILE="/root/.pimusic.vars"

	if [ -f $PI_MUSIC_VARS_FILE ]; then
		log_message info "Detected stored input in $PI_MUSIC_VARS_FILE"
	else
		echo "Please type your full name:"
		read PI_MUSIC_FULL_NAME
		echo "Please type your email:"
		read PI_MUSIC_EMAIL

		echo "#!/bin/bash" > $PI_MUSIC_VARS_FILE
		echo "" >> $PI_MUSIC_VARS_FILE
		echo "export PI_MUSIC_FULL_NAME=\"$PI_MUSIC_FULL_NAME\"" >> $PI_MUSIC_VARS_FILE
		echo "export PI_MUSIC_EMAIL=\"$PI_MUSIC_EMAIL\"" >> $PI_MUSIC_VARS_FILE

		log_message info "Input stored in '$PI_MUSIC_VARS_FILE'"
	fi

	source $PI_MUSIC_VARS_FILE

	log_message info "Collected personal info '$PI_MUSIC_FULL_NAME <$PI_MUSIC_EMAIL>'"
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

set_up_git_global_config() {
	log_message info "Setting up basic git config"
	git config --global user.name "$PI_MUSIC_FULL_NAME"
	git config --global user.email "$PI_MUSIC_EMAIL"
	git config --global core.editor vim
}

generate_ssh_key() {
	SSH_KEY_LOCATION="/home/music/.ssh/pimusic_ed25519"
	if [ -f $SSH_KEY_LOCATION ]; then
		log_message info "Detected exiting SSH key in $SSH_KEY_LOCATION"
	else
		log_message info "Setting up ssh key in $SSH_KEY_LOCATION"
		ssh-keygen -t ed25519 -C "$PI_MUSIC_EMAIL" -q -N "" -f "$SSH_KEY_LOCATION"
	fi

	log_message info "Your public key is $(cat "$SSH_KEY_LOCATION.pub")"
}

# Main portion of the script
mkdir -p logs
LOG_FILE="logs/piMusic-install.$(date +%Y-%m-%d_%H.%M.%S).log"
log_message info "Starting installation of piMusic"
log_message info "Will log to $LOG_FILE"
verify_root

collect_input
disable_swap
update_and_upgrade
install_essentials
enable_ssh_server
set_up_git_global_config
generate_ssh_key

log_message info "Installation complete!"

