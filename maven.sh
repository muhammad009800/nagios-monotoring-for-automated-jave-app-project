set -e
sudo apt update
sudo apt upgrade -y
sudo apt install git maven -y
git clone -b main https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project
mvn install
cp target/*.war /vagrant/myapp.war
echo "WAR copied and Tomcat deploy triggered ✅"
