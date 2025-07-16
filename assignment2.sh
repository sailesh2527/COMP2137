#!/bin/bash

# Assignment 2 Configuration Script
# Author: Your Name

# Function to print section headers
function print_section {
    echo ""
    echo "=== $1 ==="
    echo ""
}

# Main configuration
main() {
    print_section "Starting System Configuration"
    
    # Network Configuration
    print_section "Configuring Network"
    cat > /etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
    eth1:
      addresses: [192.168.16.21/24]
      routes:
        - to: default
          via: 192.168.16.2
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF
    netplan apply
    echo "Network configured to 192.168.16.21/24"

    # Update hosts file
    sed -i '/server1/d' /etc/hosts
    echo "192.168.16.21 server1" >> /etc/hosts
    echo "Updated /etc/hosts"

    # Install packages
    print_section "Installing Packages"
    apt-get update
    apt-get install -y apache2 squid
    systemctl enable --now apache2
    systemctl enable --now squid
    echo "Apache and Squid installed"

    # User configuration
    print_section "Configuring Users"
    users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

    for user in "${users[@]}"; do
        # Create user if not exists
        if ! id "$user" &>/dev/null; then
            useradd -m -s /bin/bash "$user"
            echo "Created user $user"
        fi

        # Setup SSH directory
        mkdir -p "/home/$user/.ssh"
        chown "$user:$user" "/home/$user/.ssh"
        chmod 700 "/home/$user/.ssh"

        # Generate SSH keys if not exist
        if [ ! -f "/home/$user/.ssh/id_rsa" ]; then
            sudo -u "$user" ssh-keygen -t rsa -f "/home/$user/.ssh/id_rsa" -N ""
        fi
        if [ ! -f "/home/$user/.ssh/id_ed25519" ]; then
            sudo -u "$user" ssh-keygen -t ed25519 -f "/home/$user/.ssh/id_ed25519" -N ""
        fi

        # Add keys to authorized_keys
        cat "/home/$user/.ssh/id_rsa.pub" >> "/home/$user/.ssh/authorized_keys"
        cat "/home/$user/.ssh/id_ed25519.pub" >> "/home/$user/.ssh/authorized_keys"
        chown "$user:$user" "/home/$user/.ssh/authorized_keys"
        chmod 600 "/home/$user/.ssh/authorized_keys"

        # Special config for dennis
        if [ "$user" == "dennis" ]; then
            usermod -aG sudo dennis
            echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> "/home/dennis/.ssh/authorized_keys"
            echo "Added special SSH key for dennis"
        fi
    done

    print_section "Configuration Complete"
}

# Execute main function
main
