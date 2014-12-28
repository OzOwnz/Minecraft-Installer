#!/bin/sh

# This script will automatically download and install the Spigot Minecraft
# server, and also setup monitoring so that the server will automatically
# be restarted should it crash for whatever reason. 
#
# This file can be downloaded directly and installed via the following command:
#
# wget -O- https://github.com/OzOwnz/Minecraft-Installer/raw/master/minecraft-installer.sh | /bin/sh
#
# Original Author:   Ryan Petris (ryan@ryanpetris.com)
# Homepage: http://www.ryanpetris.com/
# License:  GNU Affero General Public License (AGPLv3)
#           http://www.gnu.org/licenses/agpl-3.0.txt
#
# Notes:
# This script has been editted to work properly on Debian Wheezy 7.
#
# It is recommended that this script not be edited or copied from an editor
# that does not keep control characters as they are in the original file, as
# an invisible control character is used in the stop script to properly send
# a carriage return to the running minecraft server. 

# Install EPEL Repository, java, monit, and screen, and additionally
# make sure everything is up to date.

# Generic updates
apt-get update
apt-get dist-upgrade

# Download & install Monit
aptitude install monit

# Makes a directory if it doesn't already exist
mkdir -p /opt/minecraft/

# Creates a new user with a home directory of /opt/minecraft/ & sets the login
# shell to a dummy value (/sbin/nologin) so they can't login. (-M) stops from creating
# a home directory.
adduser -d /opt/minecraft/ -s /sbin/nologin -M minecraft


# Download Spigot
wget -O /opt/minecraft/spigot.jar http://tcpr.ca/files/spigot/spigot-1.8-R0.1-SNAPSHOT-latest.jar

# Permissions
chown minecraft:minecraft /opt/minecraft/
chown minecraft:minecraft /opt/minecraft/spigot.jar

# Create start and stop files
cat <<EOF > /opt/minecraft/start.sh
#!/bin/sh
cd /opt/minecraft
/usr/bin/screen -S minecraft -d -m su minecraft -s /bin/sh -c "/usr/bin/java -Xmx1G -Xms256M -jar spigot.jar nogui"
sleep 2
screen -list | grep minecraft | sed -r 's/[^0-9]*([0-9]+)\.minecraft.*/\1/' > /var/run/minecraft.pid
EOF
cat <<EOF > /opt/minecraft/stop.sh
#!/bin/sh
screen -dr minecraft -p 0 -X stuff "stop
"
sleep 5
EOF

# Make these files executable
chmod +x /opt/minecraft/*.sh

# Create monit file
cat <<EOF > /etc/monit.d/minecraft
check process minecraft with pidfile /var/run/minecraft.pid
    start program = "/opt/minecraft/start.sh"
    stop program = "/opt/minecraft/stop.sh"
EOF

/opt/minecraft/start.sh
chkconfig monit on
service monit start

echo "Spigot is installed and running!"
