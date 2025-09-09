echo "====================================="
echo "Starting Nagios installation"
echo "====================================="

echo "====================================="
echo "Installing required packages"
echo "====================================="
sudo -i 
dnf install -y gcc glibc glibc-common perl httpd php wget gd gd-devel 
dnf install -y openssl-devel
dnf update -y

echo "====================================="
echo "Downloading and Installing Nagios"
echo "====================================="
cd /tmp
wget --output-document="nagioscore.tar.gz" $(wget -q -O - https://api.github.com/repos/NagiosEnterprises/nagioscore/releases/latest  | grep '"browser_download_url":' | grep -o 'https://[^"]*')
tar xzf nagioscore.tar.gz

echo "====================================="
echo "Installing Nagios Core"
echo "====================================="
cd /tmp/nagios-*
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
systemctl enable --now httpd

echo "====================================="
echo "Installing commandmode, config and webconf"
echo "====================================="
make install-commandmode
make install-config
make install-webconf

echo "====================================="
echo "Setting up Nagios admin user"
echo "====================================="
htpasswd -cb /usr/local/nagios/etc/htpasswd.users nagiosadmin 123
systemctl restart httpd
systemctl enable --now nagios

echo "====================================="
echo "Setting up firewall"
echo "====================================="
bash /vagrant/en_firwall_nagios.sh

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
wget --output-document="nagiosplugins.tar.gz" $(wget -q -O - https://api.github.com/repos/nagios-plugins/nagios-plugins/releases/latest  | grep '"browser_download_url":' | grep -o 'https://[^"]*')
tar xzf nagiosplugins.tar.gz
cd /tmp/nagios-plugins-*
./configure
make
make install

echo "====================================="
echo "install nrpe server"
echo "====================================="
cd /tmp
wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-4.1.0/nrpe-4.1.0.tar.gz
tar xzf nrpe-4.1.0.tar.gz
cd nrpe-4.1.0
./configure --enable-command-args --with-nagios-user=nagios --with-nagios-group=nagios
make check_nrpe
cp src/check_nrpe /usr/local/nagios/libexec/

bash /vagrant/cfg_files.sh



# Restart Nagios if validation succeeds
if [ $? -eq 0 ]; then
    echo "Configuration valid. Restarting Nagios..."
    systemctl restart nagios
else
    echo "Configuration invalid. Fix errors before restarting."
    exit 1
fi
