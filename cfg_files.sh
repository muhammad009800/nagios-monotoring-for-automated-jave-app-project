
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