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
MYSQL_ROOT_PASSWORD="admin123"

mysql -u root <<EOF
-- set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- allow root to connect remotely (optional, since you chose "n")
-- comment out if you want only local root login
-- UPDATE mysql.user SET Host='%' WHERE User='root' AND Host='localhost';

-- remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- apply changes
FLUSH PRIVILEGES;
EOF

echo "MySQL secure installation completed."

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

