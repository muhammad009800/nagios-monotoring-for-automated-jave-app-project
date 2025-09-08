set -e
sudo apt update
sudo apt upgrade -y
sudo apt install nginx  -y
sudo tee /etc/nginx/sites-available/vproapp <<EOF
upstream vproapp {
server app01:8080;
}
server {
listen 80;
location / {
proxy_pass http://vproapp;
}
}
EOF
sudo rm -rf /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/vproapp /etc/nginx/sites-enabled/vproapp
echo "======= Testing Nginx configuration ======="
sudo nginx -t
sudo systemctl enable --now nginx

echo "======= Nginx setup done 😎👌======="