set -e
echo "====================================="
echo "Starting Nagios installation"
echo "====================================="

echo "====================================="
echo "Installing required packages"
echo "====================================="
sudo -i 
dnf install -y gcc glibc glibc-common perl httpd php wget gd gd-devel openssl 
dnf install -y openssl-devel

echo "====================================="
echo "Downloading and Installing Nagios"
echo "====================================="
cd /tmp
wget --output-document="nagioscore.tar.gz" $(wget -q -O - https://api.github.com/repos/NagiosEnterprises/nagioscore/releases/latest  | grep '"browser_download_url":' | grep -o 'https://[^"]*')
tar xzf nagioscore.tar.gz

echo "====================================="
echo "Installing Nagios Core"
echo "====================================="
cd /tmp/nagios-4.*
./configure
make all


echo "====================================="
echo "Setting up Nagios user and group"
echo "====================================="
make install-groups-users
usermod -a -G nagios apache

echo "====================================="
echo "Installing and starting Nagios services"
echo "====================================="
make install
make install-daemoninit
systemctl enable httpd

echo "====================================="
echo "Installing commandmode, config and webconf"
echo "====================================="
make install-commandmode
make install-config
make install-webconf

echo "====================================="
echo "Setting up firewall"
echo "====================================="
bash /vagrant/en_firwall_nagios.sh

echo "====================================="
echo "Creating Nagios systemd service if not exists"
echo "====================================="



echo "====================================="
echo "Starting Apache service and enabling Nagios service"
echo "====================================="
systemctl start httpd.service


echo "====================================="
echo "Setting up Nagios admin user"
echo "====================================="
htpasswd -cb /usr/local/nagios/etc/htpasswd.users nagiosadmin 123
systemctl restart httpd



echo "====================================="
echo "Nagios installed successfully"
echo "Access Nagios Web Interface at: http://192.168.56.16/nagios"
echo "Username: nagiosadmin"
echo "Password: 123"

echo "====================================="
echo "Nagios plugins installation started"
echo "====================================="
dnf install -y gcc glibc glibc-common make gettext automake autoconf wget openssl-devel net-snmp net-snmp-utils epel-release
dnf config-manager --set-enabled crb
dnf install -y perl-Net-SNMP
cd /tmp
wget --output-document="nagios-plugins.tar.gz" $(wget -q -O - https://api.github.com/repos/nagios-plugins/nagios-plugins/releases/latest  | grep '"browser_download_url":' | grep -o 'https://[^"]*')
tar zxf nagios-plugins.tar.gz
cd /tmp/nagios-plugins-*
./configure
make
make install

echo "====================================="
echo "Nagios plugins installed successfully"
echo "====================================="    

chown -R nagios:nagios /usr/local/nagios/libexec
chmod +x /usr/local/nagios/libexec/*

echo "====================================="
systemctl start nagios.service
systemctl stop nagios.service
systemctl restart nagios.service
systemctl status nagios.service
echo "====================================="
echo "====================================="
echo "====================================="
echo "====================================="

cd /tmp
wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-4.1.0/nrpe-4.1.0.tar.gz
tar xzf nrpe-4.1.0.tar.gz
cd nrpe-4.1.0
make check_nrpe
./configure --prefix=/usr/local/nagios --enable-command-args
sudo cp src/check_nrpe /usr/local/nagios/libexec/


echo "===================================================================="
echo "===================================================================="
echo "===================================================================="
echo "===================================================================="
echo "===================================================================="
echo "===================================================================="
echo "===================================================================="
echo "===================================================================="
echo "===================================================================="
echo "===================================================================="
echo "Starting configuration scripts..."
echo "===================================================================="
cfg_file="/usr/local/nagios/etc/objects/commands.cfg"
# Check if command already exists
if ! grep -q "define command" "$cfg_file" | grep -q "check_nrpe"; then
    cat <<EOF >> "$cfg_file"

define command {
    command_name    check_nrpe
    command_line    /usr/local/nagios/libexec/check_nrpe -H \$HOSTADDRESS\$ -c \$ARG1\$
}
EOF
echo "===================================================================="
    echo "✅ check_nrpe command added to $cfg_file"
echo "===================================================================="
else
echo "===================================================================="
    echo "⚠️ check_nrpe command already exists in $cfg_file"
echo "===================================================================="
fi



echo "===================================================================="
echo "Creating vms.cfg with host and service definitions..."
echo "===================================================================="

cat <<'EOF' | sudo tee /usr/local/nagios/etc/objects/vms.cfg > /dev/null
define hostgroup {
    hostgroup_name  vm-servers
    alias           Virtual Machines
    members         web01,db01,app01,rmq01,mc01
}

define host {
    use             linux-server
    host_name       web01
    alias           Web Server
    address         192.168.56.10
}

define host {
    use             linux-server
    host_name       db01
    alias           Database Server
    address         192.168.56.14
}

define host {
    use             linux-server
    host_name       app01
    alias           Application Server
    address         192.168.56.15
}

define host {
    use             linux-server
    host_name       rmq01
    alias           RabbitMQ Server
    address         192.168.56.11
}

define host {
    use             linux-server
    host_name       mc01
    alias           Memcached Server
    address         192.168.56.12
}

define service {
    use                     generic-service
    hostgroup_name          vm-servers
    service_description     Load
    check_command           check_nrpe!check_load
}

define service {
    use                     generic-service
    hostgroup_name          vm-servers
    service_description     Disk Usage
    check_command           check_nrpe!check_disk
}

define service {
    use                     generic-service
    hostgroup_name          vm-servers
    service_description     Users
    check_command           check_nrpe!check_users
}

define service {
    use                     generic-service
    hostgroup_name          vm-servers
    service_description     Processes
    check_command           check_nrpe!check_procs
}
EOF
echo "===================================================================="
echo "✅ vms.cfg created with host and service definitions."    
echo "===================================================================="

echo "===================================================================="
echo "Registering vms.cfg in nagios.cfg..."
echo "===================================================================="
nagios_cfg="/usr/local/nagios/etc/nagios.cfg"
vms_cfg="cfg_file=/usr/local/nagios/etc/objects/vms.cfg"

# Check if entry already exists
if grep -Fxq "$vms_cfg" "$nagios_cfg"; then
    echo "✅ vms.cfg is already registered in $nagios_cfg"
else
    echo "$vms_cfg" | sudo tee -a "$nagios_cfg" > /dev/null
    echo "✅ Added vms.cfg to $nagios_cfg"
fi
echo "===================================================================="
echo "All configuration scripts completed."
echo "===================================================================="
echo "===================================================================="
echo "===================================================================="
echo "===================================================================="
echo "===================================================================="
echo "===================================================================="
echo "===================================================================="
echo "===================================================================="
echo "===================================================================="


echo "====================================="
echo "Validate Nagios configuration"
echo "====================================="
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

echo "====================================="
echo "Restart Nagios service"
echo "====================================="
# Restart Nagios if validation succeeds
if [ $? -eq 0 ]; then
    echo "Configuration valid. Restarting Nagios..."
    systemctl restart nagios
else
    echo "Configuration invalid. Fix errors before restarting."
    exit 1
fi
