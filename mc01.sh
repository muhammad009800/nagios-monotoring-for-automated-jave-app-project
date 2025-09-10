set -e 

echo "=======updating system========"
sudo yum update -y

echo "=========== install bash ==============="  
if ! command -v bash &> /dev/null
then 
	echo "bash not found install it "
	sudo yum install bash -y
else
	echo "bash already installed"
fi

echo "=========== install needed pkg for memcache & install it ==============="
sudo dnf install -y epel-release
sudo dnf install memcached -y
sudo systemctl enable --now memcached
sudo systemctl is-active memcached

echo "======== edit config of memcached =========="
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/sysconfig/memcached
sudo systemctl restart memcached

echo "=========== open firewall for memcached ==============="
sudo dnf install -y firewalld
sudo systemctl enable --now firewalld
sudo firewall-cmd --add-port=11211/tcp
sudo firewall-cmd --runtime-to-permanent
sudo firewall-cmd --add-port=11111/udp
sudo firewall-cmd --runtime-to-permanent
sudo memcached -p 11211 -U 11111 -u memcached -d
echo "memcached is ready to use 😎👌"