sudo -i
dnf install -y firewalld
systemctl enable --now firewalld
firewall-cmd --zone=public --add-port=80/tcp
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload