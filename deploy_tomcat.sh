#!/bin/bash
set -euo pipefail

sudo mv /vagrant/myapp.war /usr/local/tomcat/webapps/

echo "Starting Tomcat and fixing permissions..."
sudo systemctl start tomcat
sudo chown -R tomcat.tomcat /usr/local/tomcat/webapps
sudo systemctl restart tomcat
echo "Tomcat deployment done ✅"
