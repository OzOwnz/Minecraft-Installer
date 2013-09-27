#!/bin/sh

# This script will automatically download and install the Spigot Minecraft
# server, and also setup monitoring so that the server will automatically
# be restarted should it crash for whatever reason. 
#
# This file can be downloaded directly and installed via the following command:
#
# wget -O- --no-check-certificate https://petris.io/minecraft-installer/mainline/blobs/raw/master/minecraft-installer.sh | /bin/sh
#
# Author: Ryan Petris (ryan@petris.tel)
# Homepage: http://ryanpetris.com/
# License: GNU Affero General Public License (AGPLv3)
#          http://www.gnu.org/licenses/agpl-3.0.txt
#
# Notes:
# This script was written to run properly on CentOS 6. While other
# distributions may work, they have not been tested. Additionally, this
# script will download and install the EPEL repository and update. If
# this is not safe for your system (i.e., you have another repository
# that may have conflicting packages), then you will need to remove that
# line. You will need to manually install monit from another source for
# monitoring to work properly.
#
# It is recommended that this script not be edited or copied from an editor
# that does not keep control characters as they are in the original file, as
# an invisible control character is used in the stop script to properly send
# a carriage return to the running minecraft server. 

# Install EPEL Repository, java, monit, and screen, and additionally
# make sure everything is up to date.
yum install -y http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
yum update
yum install -y java-1.7.0-openjdk monit screen

# Create the minecraft directory and create a user for the minecraft
# server that is not allowed to login.
mkdir -p /opt/minecraft/
adduser -d /opt/minecraft/ -s /sbin/nologin -M minecraft

# Download Spigot
wget -O /opt/minecraft/minecraft_server.jar http://ci.md-5.net/job/Spigot/lastSuccessfulBuild/artifact/Spigot-Server/target/spigot.jar

# Permissions
chown minecraft:minecraft /opt/minecraft/
chown minecraft:minecraft /opt/minecraft/minecraft_server.jar

# Create start and stop files
cat <<EOF > /opt/minecraft/start.sh
#!/bin/sh
cd /opt/minecraft
/usr/bin/screen -S minecraft -d -m su minecraft -s /bin/sh -c "/usr/bin/java -Xmx1024M -Xms1024M -jar minecraft_server.jar nogui"
screen -list | grep minecraft | sed -r 's/[^0-9]*([0-9]+)\.minecraft.*/\1/' > /var/run/minecraft.pid
EOF
cat <<EOF > /opt/minecraft/stop.sh
#!/bin/sh
screen -dr minecraft -p 0 -X stuff "stop"
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

echo "Minecraft is installed and running!"