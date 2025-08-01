#!/bin/bash

VERBOSE=false
trap '' HUP INT TERM

log() {
    logger "$1"
    $VERBOSE && echo "$1"
}

update_hostname() {
    local desired=$1
    current=$(hostname)
    if [ "$current" != "$desired" ]; then
        echo "$desired" > /etc/hostname
        hostnamectl set-hostname "$desired"
        sed -i "s/127.0.1.1.*/127.0.1.1 $desired/" /etc/hosts
        log "Hostname changed from $current to $desired"
    else
        $VERBOSE && echo "Hostname already set to $desired"
    fi
}

update_ip() {
    local desired_ip=$1
    local iface=$(ip route | grep default | awk '{print $5}')
    current_ip=$(ip addr show "$iface" | grep -w inet | awk '{print $2}' | cut -d/ -f1)

    if [ "$current_ip" != "$desired_ip" ]; then
        cat > /etc/netplan/01-config.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $iface:
      addresses: [$desired_ip/24]
      dhcp4: no
EOF
        netplan apply
        sed -i "/$desired_ip/d" /etc/hosts
        echo "$desired_ip $(hostname)" >> /etc/hosts
        log "IP changed from $current_ip to $desired_ip on $iface"
    else
        $VERBOSE && echo "IP already set to $desired_ip"
    fi
}

update_hostentry() {
    local name=$1
    local ip=$2
    if grep -q "$name" /etc/hosts; then
        sed -i "/$name/d" /etc/hosts
    fi
    echo "$ip $name" >> /etc/hosts
    log "Host entry updated: $ip $name"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -verbose) VERBOSE=true ;;
        -name) shift; update_hostname "$1" ;;
        -ip) shift; update_ip "$1" ;;
        -hostentry) shift; hostentry_name="$1"; shift; hostentry_ip="$1"; update_hostentry "$hostentry_name" "$hostentry_ip" ;;
        *) echo "Invalid option $1"; exit 1 ;;
    esac
    shift
done
 
