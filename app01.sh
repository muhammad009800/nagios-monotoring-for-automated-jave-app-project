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


echo "=========== install needed pkg for tomcat & install it ==============="
sudo yum install -y epel-release
sudo yum install java-11-openjdk java-11-openjdk-devel wget curl tar git firewalld -y
cd /tmp/

if [ ! -f apache-tomcat-9.0.75.tar.gz ]; then
	wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.75/bin/apache-tomcat-9.0.75.tar.gz
fi


if [ ! -d /usr/local/tomcat/bin ]; then
    sudo tar xzvf /tmp/apache-tomcat-9.0.75.tar.gz 
else
    echo "Tomcat already extracted, skipping..."
fi



echo "=========== create user for tomcat & copy data to tomcat home ==============="

sudo mkdir -p /usr/local/tomcat
if ! id tomcat &>/dev/null; then
    sudo useradd --system --home-dir /usr/local/tomcat --shell /sbin/nologin tomcat
else
    echo "User tomcat already exists"
fi
sudo rsync -a /tmp/apache-tomcat-9.0.75/ /usr/local/tomcat/

sudo chown -R tomcat.tomcat /usr/local/tomcat




echo "=========== create tomcat service file ==============="
sudo tee /etc/systemd/system/tomcat.service > /dev/null <<EOF && echo "✅ Tomcat service file ready"
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat
Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk"
Environment="CATALINA_PID=/usr/local/tomcat/temp/tomcat.pid"
Environment="CATALINA_HOME=/usr/local/tomcat"
Environment="CATALINA_BASE=/usr/local/tomcat"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"

ExecStart=/usr/local/tomcat/bin/startup.sh
ExecStop=/usr/local/tomcat/bin/shutdown.sh

Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF




echo "=========== demon reload ==============="
 
sudo systemctl daemon-reload




echo "=========== enable and start  ==============="


sudo systemctl enable --now tomcat



echo "=========== enable firewall ==============="
sudo dnf install -y firewalld
sudo systemctl enable --now firewalld
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
echo "=========== check listening ==============="

if sudo ss -tulnp | grep -q 8080; then
    echo "Tomcat is listening on port 8080 ✅"
else
    echo "WARNING: Tomcat is NOT listening on port 8080 ⚠️"
fi


sudo systemctl stop tomcat
sudo rm -rf /usr/local/tomcat/webapps/ROOT*
sudo cp -f /vagrant/myapp.war /usr/local/tomcat/webapps/ROOT.war


sudo systemctl start tomcat
sudo chown tomcat.tomcat /usr/local/tomcat/webapps -R
sudo systemctl restart tomcat

echo "==== Provisioning tomcat DONE ✅😎👌 ===="
