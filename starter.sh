#!/bin/sh

# This script will automatically download and install the Spigot Minecraft
# server, and also setup monitoring so that the server will automatically
# be restarted should it crash for whatever reason. 
#
# This file can be downloaded directly and installed via the following command:
#
# wget -O- https://github.com/OzOwnz/Minecraft-Installer/raw/master/starter.sh | /bin/sh
#
# Original Author   Ryan Petris (ryan@ryanpetris.com)
# Homepage http//www.ryanpetris.com/
# License  GNU Affero General Public License (AGPLv3)
#           http//www.gnu.org/licenses/agpl-3.0.txt
#
# Notes
# This script has been editted to work properly on Debian Wheezy 7.
#
# It is recommended that this script not be edited or copied from an editor
# that does not keep control characters as they are in the original file, as
# an invisible control character is used in the stop script to properly send
# a carriage return to the running minecraft server. 

# Install EPEL Repository, java, monit, and screen, and additionally
# make sure everything is up to date.

# Generic updates
#apt-get update
#apt-get dist-upgrade

# Download & install Monit
aptitude install monit

# Makes directories for each of the servers if they don't already exist
mkdir -p /home/oz
mkdir -p /home/oz/proxy
mkdir -p /home/oz/login
mkdir -p /home/oz/hub
mkdir -p /home/oz/overworld
mkdir -p /home/oz/creative

# Creates a new user (oz & monit) both with a home directory of /home/oz/ & sets the login
# shell to a dummy value (/sbin/nologin) so 'monit' can't login. (-M) stops from creating
# a home directory.
#NOTES: adduser -d /home/oz/ -s /sbin/nologin -M monit
adduser oz
# ^^^CHECK IF /home/oz/<- (note last /) IS CORRECT

# Update Spigot (illegal download link for kicks, never used it before...)
wget -O /home/oz/spigot.jar 'http://tcpr.ca/files/spigot/spigot-1.8-R0.1-SNAPSHOT-latest.jar'
# Copy to all directories
cp -u /home/oz/spigot.jar /home/oz/proxy
cp -u /home/oz/spigot.jar /home/oz/login
cp -u /home/oz/spigot.jar /home/oz/hub
cp -u /home/oz/spigot.jar /home/oz/overworld
cp -u /home/oz/spigot.jar /home/oz/creative
# Remove original jar
rm -f /home/oz/spigot.jar

# Gives complete access of everything in /home/oz to oz & monit
chown -R oz /home/oz
#chown -R monit /home/oz

# How to kill a server
# 1. Softly, /stop
# 2. Wait and check if it's dead
# 3. Aggressively kill the process via pid (kill -9 PID)

# Creates a kill-if-running, and start script for the login server
cat <<EOF > /home/oz/start_login.sh
#!/bin/sh
echo "Attempting to kill login server..."
kill -9 $(cat /home/oz/login.pid)
echo "Attempting to quit login server screen session..."
screen -S login -X quit
echo "Attempting to open login server directory..."
cd /home/oz/login
echo "Attempting to create a new screen session and start the server..."
screen -S login -d -m su oz "java -Xms32m -Xmx128m -jar spigot.jar -o false --nojline"
echo "Saving login server's pid to file..."
echo $! >/home/oz/login.pid
EOF


cat <<EOF > /home/oz/stop_login.sh
#!/bin/sh
screen -dr login -p 0 -X stuff "stop
"
EOF

# Gives these files executability
chmod +x /home/oz/*.sh

# Create monit file
cat <<EOF > /etc/monit.d/minecraft
check process login with pidfile /home/oz/login.pid
    start program = "/home/oz/start_login.sh"
    stop program = "/home/oz/stop_login.sh"
EOF

/home/oz/start_login.sh
chkconfig monit on
service monit start

echo "Completed!"
