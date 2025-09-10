set -e


echo "==== Updating system ===="
sudo yum update -y


echo "==== install bash ===="
if ! command -v bash &> /dev/null
then
    echo "bash not found, installing..."
    sudo yum install -y bash
else
    echo "bash already installed"
fi


echo "==== Installing required packages ===="
sudo yum install epel-release -y
sudo yum install git mariadb-server -y


echo "==== Starting and enabling MariaDB ===="
sudo systemctl enable --now mariadb


echo "==== Securing MariaDB ===="
sudo bash /vagrant/secure_mysql.sh


echo "==== Initializing Tomcat DB ===="
sudo mysql -u root -padmin123 < /vagrant/init_db.sql


echo "==== Cloning GitHub project ===="
if [ -d "/home/vagrant/vprofile-project" ]; then
    echo "Project exists, removing old copy..."
    rm -rf /home/vagrant/vprofile-project
fi
sudo git clone -b main https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project


echo "==== Importing DB backup ===="
sudo mysql -u root -padmin123 accounts < src/main/resources/db_backup.sql


echo "==== Verifying imported tables ===="
sudo mysql -u root -padmin123 accounts <<EOF
SHOW TABLES;
EOF


echo "==== Restarting MariaDB ===="
sudo systemctl restart mariadb


echo "==== Configuring firewall ===="
sudo dnf install -y firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent
sudo firewall-cmd --reload
sudo systemctl restart mariadb

echo "==== Provisioning DB DONE ✅😎👌 ===="

