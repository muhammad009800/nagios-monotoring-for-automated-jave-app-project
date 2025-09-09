#!/bin/bash
set -e

echo "====================================="
echo "Provisioning Nagios NRPE Client (Ubuntu)"
echo "====================================="

# Update package index
apt-get update -yq

# Install NRPE server and Nagios plugins
apt-get install -yq nagios-nrpe-server nagios-plugins nagios-plugins-basic nagios-plugins-standard

# Backup default NRPE config
cp /etc/nagios/nrpe.cfg /etc/nagios/nrpe.cfg.bak

# Configure NRPE
cat <<EOF >/etc/nagios/nrpe.cfg
log_facility=daemon
pid_file=/var/run/nagios/nrpe.pid
server_port=5666
nrpe_user=nagios
nrpe_group=nagios
allowed_hosts=127.0.0.1,192.168.56.16   # replace with Nagios server IP

dont_blame_nrpe=1
allow_bash_command_substitution=0
debug=0
command_timeout=60
connection_timeout=300

# Standard checks
command[check_users]=/usr/lib/nagios/plugins/check_users -w 5 -c 10
command[check_load]=/usr/lib/nagios/plugins/check_load -r -w 15,10,5 -c 30,25,20
command[check_disk]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /
command[check_procs]=/usr/lib/nagios/plugins/check_procs -w 150 -c 200
EOF

# Enable and restart NRPE
systemctl enable --now nagios-nrpe-server
systemctl restart nagios-nrpe-server

echo "====================================="
echo "NRPE Client Installed and Running"
echo "====================================="
systemctl status nagios-nrpe-server --no-pager