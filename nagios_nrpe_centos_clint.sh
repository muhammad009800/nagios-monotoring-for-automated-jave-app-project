set -e
sudo -i 

echo "====================================="
echo "Starting Nagios NRPE Client installation"
echo "====================================="

NAGIOS_SERVER_IP="192.168.56.16"
NRPE_CFG="/etc/nagios/nrpe.cfg"

# Install repos
dnf install -y epel-release epel-next-release || true
dnf update -y


# Install NRPE + plugins
dnf install -y nrpe || true
dnf install -y monitoring-plugins || \
dnf install -y nagios-plugins-disk nagios-plugins-procs nagios-plugins-users nagios-plugins-load nagios-plugins-swap



echo "====================================="
echo "Overwriting NRPE configuration"
echo "====================================="

cat <<EOL | sudo tee $NRPE_CFG
log_facility=daemon
pid_file=/var/run/nrpe/nrpe.pid
server_port=5666
nrpe_user=nrpe
nrpe_group=nrpe
allowed_hosts=127.0.0.1,${NAGIOS_SERVER_IP}
dont_blame_nrpe=0
debug=0
command_timeout=60
connection_timeout=120

# Nagios checks
command[check_users]=/usr/lib64/nagios/plugins/check_users -w 5 -c 10
command[check_load]=/usr/lib64/nagios/plugins/check_load -w 15,10,5 -c 30,25,20
command[check_disk]=/usr/lib64/nagios/plugins/check_disk -w 20% -c 10% -p /
command[check_procs]=/usr/lib64/nagios/plugins/check_procs -w 150 -c 200
command[check_swap]=/usr/lib64/nagios/plugins/check_swap -w 20% -c 10%
EOL

echo "====================================="
echo "Enable and start NRPE service"
echo "====================================="
systemctl enable --now nrpe
systemctl restart nrpe
systemctl status nrpe --no-pager

echo "====================================="
echo "Setting up firewall"
echo "====================================="
bash /vagrant/en_firwall_nagios.sh

echo "====================================="
echo "NRPE Client Installed and Running"
echo "====================================="