#!/bin/bash
set -e

echo "====================================="
echo "Starting Nagios Server Provisioning"
echo "====================================="

# --- Install Dependencies ---
dnf install -y gcc glibc glibc-common perl httpd php wget gd gd-devel openssl-devel
dnf install -y net-snmp net-snmp-utils epel-release
dnf config-manager --set-enabled crb
dnf install -y perl-Net-SNMP
dnf update -y

# --- Download and Install Nagios Core ---
cd /tmp
wget --output-document="nagioscore.tar.gz" $(wget -q -O - https://api.github.com/repos/NagiosEnterprises/nagioscore/releases/latest | grep '"browser_download_url":' | grep -o 'https://[^"]*')
tar xzf nagioscore.tar.gz
cd /tmp/nagios-*
./configure
make all
make install-groups-users
usermod -a -G nagios apache
make install
make install-daemoninit
make install-commandmode
make install-config
make install-webconf

# --- Nagios Admin User ---
htpasswd -cb /usr/local/nagios/etc/htpasswd.users nagiosadmin 123
systemctl enable --now httpd
systemctl enable --now nagios || true

# --- Nagios Plugins ---
cd /tmp
wget --output-document="nagiosplugins.tar.gz" $(wget -q -O - https://api.github.com/repos/nagios-plugins/nagios-plugins/releases/latest | grep '"browser_download_url":' | grep -o 'https://[^"]*')
tar xzf nagiosplugins.tar.gz
cd /tmp/nagios-plugins-*
./configure
make
make install

# --- NRPE check plugin ---
cd /tmp
wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-4.1.0/nrpe-4.1.0.tar.gz
tar xzf nrpe-4.1.0.tar.gz
cd nrpe-4.1.0
./configure --enable-command-args --with-nagios-user=nagios --with-nagios-group=nagios
make check_nrpe
cp src/check_nrpe /usr/local/nagios/libexec/

# ===============================
# Create Required Config Files
# ===============================

CFG_DIR="/usr/local/nagios/etc/objects"

# --- templates.cfg ---
cat > $CFG_DIR/templates.cfg <<EOF
define host {
    name                            linux-server
    use                             generic-host
    check_period                    24x7
    max_check_attempts              5
    check_interval                  5
    retry_interval                  1
    register                        0
}

define service {
    name                            generic-service
    active_checks_enabled           1
    check_interval                  5
    retry_interval                  1
    max_check_attempts              3
    check_period                    24x7
    notification_interval           30
    notification_period             24x7
    register                        0
}
EOF

# --- commands.cfg ---
cat > $CFG_DIR/commands.cfg <<EOF
define command {
    command_name    check_nrpe
    command_line    \$USER1$/check_nrpe -H \$HOSTADDRESS$ -c \$ARG1$
}
EOF

# --- contacts.cfg ---
cat > $CFG_DIR/contacts.cfg <<EOF
define contact {
    contact_name                    nagiosadmin
    alias                           Nagios Admin
    service_notification_period     24x7
    host_notification_period        24x7
    service_notification_options    w,u,c,r
    host_notification_options       d,u,r
    service_notification_commands   notify-service-by-email
    host_notification_commands      notify-host-by-email
    email                           nagios@localhost
}

define contactgroup {
    contactgroup_name   admins
    alias               Nagios Administrators
    members             nagiosadmin
}
EOF

# --- timeperiods.cfg ---
cat > $CFG_DIR/timeperiods.cfg <<EOF
define timeperiod {
    timeperiod_name 24x7
    alias           24 Hours A Day, 7 Days A Week
    sunday          00:00-24:00
    monday          00:00-24:00
    tuesday         00:00-24:00
    wednesday       00:00-24:00
    thursday        00:00-24:00
    friday          00:00-24:00
    saturday        00:00-24:00
}
EOF

# --- vms.cfg ---
cat > $CFG_DIR/vms.cfg <<EOF
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

# Services for hostgroup
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

# ===============================
# Update nagios.cfg to include files
# ===============================
NAGIOS_CFG="/usr/local/nagios/etc/nagios.cfg"

for f in templates.cfg commands.cfg contacts.cfg timeperiods.cfg vms.cfg; do
    grep -q "^cfg_file=$CFG_DIR/$f" $NAGIOS_CFG || echo "cfg_file=$CFG_DIR/$f" >> $NAGIOS_CFG
done

# --- Validate and Restart ---
/usr/local/nagios/bin/nagios -v $NAGIOS_CFG

if [ $? -eq 0 ]; then
    echo "Configuration valid. Restarting Nagios..."
    systemctl restart nagios
    echo "Nagios is up and running!"
else
    echo "Configuration invalid. Please fix errors."
    exit 1
fi
echo "====================================="
echo "Nagios Server Provisioning Completed"
echo "Access Nagios Web Interface at: http://192.168.56.16/nagios"