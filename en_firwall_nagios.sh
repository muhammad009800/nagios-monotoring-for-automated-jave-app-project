sudo -i
sudo dnf install -y firewalld
sudo firewall-cmd --zone=public --add-port=80/tcp
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --zone=public --add-port=5666/tcp
sudo firewall-cmd --zone=public --add-port=5666/tcp --permanent
sudo firewall-cmd --reload
sudo systemctl enable --now firewalld
