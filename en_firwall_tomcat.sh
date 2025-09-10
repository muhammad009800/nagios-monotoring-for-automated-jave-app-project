sudo -i

sudo dnf install -y firewalld
sudo systemctl enable --now firewalld
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
