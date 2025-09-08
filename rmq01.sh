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


echo "=========== install needed pkg for rabbitmq & install it ==============="
sudo yum install -y epel-release
sudo yum install wget curl -y
cd /tmp/
sudo dnf -y install centos-release-rabbitmq-38
sudo dnf --enablerepo=centos-rabbitmq-38 -y install rabbitmq-server
sudo systemctl enable --now rabbitmq-server

echo "=========== Setup access to user test and make it admin ==============="
sudo sh -c 'echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config'
sudo rabbitmqctl add_user test test
sudo rabbitmqctl set_user_tags test administrator
sudo systemctl restart rabbitmq-server

echo "=========== Starting the firewall and allowing the port 5672 to access rabbitmq ==============="
sudo bash /vagrant/en_firwall_rmq.sh
echo "rabbitmq is ready to use 😎👌"