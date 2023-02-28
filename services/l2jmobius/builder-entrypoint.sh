#!/bin/sh

set -e

# Build everything up to "jar" target
ant -f ./src/build.xml jar

# Copy game, libs, and login dist folders
cp -r /opt/l2jmobius/src/dist/libs /opt/l2jmobius/ready/
cp -r /opt/l2jmobius/src/dist/login /opt/l2jmobius/ready/
cp -r /opt/l2jmobius/src/dist/game /opt/l2jmobius/ready/
cp -r /opt/l2jmobius/build/dist/libs /opt/l2jmobius/ready/

# Create log dirs if they don't exist
mkdir -p /opt/l2jmobius/ready/login/log
mkdir -p /opt/l2jmobius/ready/game/log

# Make all .sh scripts executable.
chmod +x /opt/l2jmobius/ready/login/*.sh
chmod +x /opt/l2jmobius/ready/game/*.sh

# Unpack geodata
unzip -oq /opt/l2jmobius/geodata/*.zip -d /opt/l2jmobius/ready/game/data/geodata/

# Edit ./ready/game/config/Server.ini and
# ./ready/login/config/LoginServer.ini with
# database credentials and make servers bind to any available IP.

# Server.ini
# @19 "LoginHost = 127.0.0.1" -> "LoginHost = 0.0.0.0"
# @45 localhost -> l2jmobius_db
# @48 "Login = root" -> "Login = $MARIADB_USER"
# @51 "Password = " -> "Password = $MARIADB_PASSWORD"
sed -i "
19c\LoginHost = l2jmobius_login\r
45s/localhost/l2jmobius_db/
48c\Login = $MARIADB_USER\r
51c\Password = $MARIADB_PASSWORD\r
" ./ready/game/config/Server.ini

# LoginServer.ini
# @28 "LoginHostname = 127.0.0.1" = "LoginHostname = 0.0.0.0"
# @45 localhost -> l2jmobius_db
# @48 "Login = root" -> "Login = $MARIADB_USER"
# @51 "Password = " -> "Password = $MARIADB_PASSWORD"
sed -i "
28c\LoginHostname = 0.0.0.0\r
45s/localhost/l2jmobius_db/
48c\Login = $MARIADB_USER\r
51c\Password = $MARIADB_PASSWORD\r
" ./ready/login/config/LoginServer.ini

# Create ipconfig.xml so the game server become available on remote server (default is localhost)
cat > ./ready/game/config/ipconfig.xml <<- EOM
<?xml version="1.0" encoding="UTF-8"?>
<!-- Note: If file is named "ipconfig.xml" this data will be used as network configuration, otherwise server will configure it automatically! -->
<!-- Externalhost here (Internet IP) or Localhost IP for local test -->
<gameserver address="127.0.0.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="../data/xsd/ipconfig.xsd">
	<!-- Localhost here -->
	<define subnet="127.0.0.0/8" address="127.0.0.1" />
	<!-- Internalhosts here (LANs IPs) -->
	<define subnet="192.168.1.0/24" address="192.168.1.2" />
</gameserver>
EOM

exec "$@"

