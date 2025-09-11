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
CONFIG_FILE="/etc/rabbitmq/rabbitmq.config"
if ! grep -q "loopback_users" "$CONFIG_FILE" 2>/dev/null; then
    echo '[{rabbit, [{loopback_users, []}]}].' | sudo tee "$CONFIG_FILE" >/dev/null
    echo "✅ RabbitMQ config set"
else
    echo "ℹ RabbitMQ config already set"
fi

# 2️⃣ Add 'test' user if it doesn't exist
if ! sudo rabbitmqctl list_users | grep -q '^test'; then
    sudo rabbitmqctl add_user test test
    echo "✅ RabbitMQ user 'test' created"
else
    echo "ℹ RabbitMQ user 'test' already exists"
fi

# 3️⃣ Set 'administrator' tag for 'test' user if not already set
if ! sudo rabbitmqctl list_users | grep '^test' | grep -q 'administrator'; then
    sudo rabbitmqctl set_user_tags test administrator
    echo "✅ RabbitMQ user 'test' tagged as administrator"
else
    echo "ℹ RabbitMQ user 'test' already has administrator tag"
fi

# 4️⃣ Restart RabbitMQ
sudo systemctl restart rabbitmq-server
echo "✅ RabbitMQ restarted and ready"

echo "=========== Starting the firewall and allowing the port 5672 to access rabbitmq ==============="
sudo dnf install -y firewalld
sudo systemctl enable --now firewalld
sudo firewall-cmd --add-port=5672/tcp
sudo firewall-cmd --runtime-to-permanent
sudo systemctl start rabbitmq-server
sudo systemctl enable rabbitmq-server
sudo systemctl status rabbitmq-server
echo "rabbitmq is ready to use 😎👌"