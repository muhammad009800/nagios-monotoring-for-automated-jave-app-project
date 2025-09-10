sudo -i
sudo dnf install -y firewalld
sudo systemctl enable --now firewalld
sudo firewall-cmd --add-port=11211/tcp
sudo firewall-cmd --runtime-to-permanent
sudo firewall-cmd --add-port=11111/udp
sudo firewall-cmd --runtime-to-permanent
sudo memcached -p 11211 -U 11111 -u memcached -d
