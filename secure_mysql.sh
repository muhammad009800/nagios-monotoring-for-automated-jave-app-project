#!/bin/bash
# secure-mysql.sh

MYSQL_ROOT_PASSWORD="admin123"

mysql -u root <<EOF
-- set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- allow root to connect remotely (optional, since you chose "n")
-- comment out if you want only local root login
-- UPDATE mysql.user SET Host='%' WHERE User='root' AND Host='localhost';

-- remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- apply changes
FLUSH PRIVILEGES;
EOF

echo "MySQL secure installation completed."

