#!/bin/bash

function install_prerequisites
{
  apt-get install sysstat netdiscover ufw python3 snmp snmpd -y
}

function log_file_creation
{
  username="aniket"
  mkdir /home/$username/network_analyzer/
  touch /home/$username/network_analyzer/sar_raw_data.txt
  touch /home/$username/network_analyzer/interface_raw_data.txt
  touch /home/$username/network_analyzer/interface_data.txt
  touch /home/$username/network_analyzer/raw_ip_log.txt
  touch /home/$username/network_analyzer/ip_data.txt
}

function ufw_manager
{
  ufw enable
  ufw allow 22/tcp
  ufw allow 22/udp
  ufw allow 80/tcp
  ufw allow 80/udp
  ufw allow 443/tcp
  ufw allow 443/udp
  ufw allow 3306/tcp
  ufw allow 3306/udp
  ufw allow 161/udp
}

#install_prerequisites
log_file_creation
#ufw_manager
