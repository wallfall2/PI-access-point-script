#!/bin/bash
#shebang
#I have absulotely no clue if any of this work cuz i cant test it but... fingers crossed :)
#First time writing a bash script that will be used properly lmao 

#If any commands fail it will halt the script 
set -e

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color


# Update and Upgrade the usual
sudo apt update
sudo apt upgrade

# Install required packages
sudo apt install dnsmasq hostapd

if [ $? -eq 0 ]; then
    echo "${GREEN} dnsmasq & hostpad successfully installed! ${NC}"
else
    echo "${RED} INSTALL FAILED!!! CHECK ERRORS! ${NC}"
fi

# Configure static IP Address
sudo sh -c 'echo "interface wlan0" >> /etc/dhcpcd.conf'
echo "Attempting to change the statip IP"
sudo sh -c 'echo "static ip_address=192.168.4.1/24" >> /etc/dhcpcd.conf'

if [ $? -eq 0 ]; then
    echo "${GREEN} Static IP configured ${NC}"
else
    echo "${RED} Error setting static IP, Check Errors and check dhcpcd.conf ${NC}"
fi

# Configure DNS and DHCP
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo sh -c 'echo "no-resolv" >> /etc/dnsmasq.conf'
sudo sh -c 'echo "interface=wlan0" >> /etc/dnsmasq.conf'
sudo sh -c 'echo "dhcp-range=192.168.0.11,192.168.0.30,255.255.255.0,24h" >> /etc/dnsmasq.conf'
sudo sh -c 'echo "server=8.8.8.8" >> /etc/dnsmasq.conf'
sudo sh -c 'echo "server=8.8.4.4" >> /etc/dnsmasq.conf'

sudo sh -c 'cat << EOF > /etc/systemd/network/wlan0.network
[Match]
Name=wlan0

[Network]
Address=192.168.0.103/24
Gateway=192.168.0.1
DNS=192.168.0.1
EOF'


# Configure Hostapd I am hoping to god this works // change ssid to youw own network name // uncomment the last 5 lines and change 'passphrase' if you would like to add a password
sudo sh -c 'cat << EOF > /etc/hostapd/hostapd.conf
interface=wlan0
bridge=br0
driver=nl80211
ssid=PI-AP 
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
#wpa=2
#wpa_passphrase=Password1234
#wpa_key_mgmt=WPA-PSK
#wpa_pairwise=TKIP
#rsn_pairwise=CCMP
EOF'

# Update Hostapd Configuration
sudo sed -i 's/#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd

if [ $? -eq 0 ]; then
    echo "${GREEN} Updated Hostapd Config ${NC}"
else
    echo "${RED} ERROR UPDATING HOSTAPD CONFIG!! Check errors or something else tbh i have no idea how this command works just found it on stackoverflow ${NC}"
fi

# Enable IP Forwarding
sudo sed -i '/#net.ipv4.ip_forward=1/s/^#//g' /etc/sysctl.conf

if [ $? -eq 0 ]; then
    echo "${GREEN} IP Fowarding configured ${NC}"
else
    echo "${RED} Enabling IP forwarding failed. check errors. shouldnt fail as just uncommenting line ${NC}"
fi

# Enable NAT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

if [ $? -eq 0 ]; then
    echo "${GREEN} NAT setup. i am suprised ${NC}"
else
    echo "${RED} ERROR tbh i had no clue if this would work or not. check errors. if to no avail could skip ${NC}"
fi
#Unmasks hostpad
sudo systemctl unmask hostapd
sudo systemctl enable hostapd

#Restarts everything
sudo systemctl start hostapd
sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq

echo "Made by louis ~~o:>" 

#SSH session will be terminated 
sudo systemctl restart systemd-networkd

# Start Services on Boot
sudo sed -i '/exit 0/ i iptables-restore < /etc/iptables.ipv4.nat' /etc/rc.local

# Reboot
#sudo reboot

#Made by louis
#~~o:> 

