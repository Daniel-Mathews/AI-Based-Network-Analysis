#!/bin/bash

function update_repo
{
  sudo apt-get update -y
}

function install_snmp_packages
{
  sudo apt-get install snmp snmpd ufw
  sudo rm -rf /etc/snmp/snmpd.conf
  sudo cp /home/aniket/network_analyzer/snmpd.conf /etc/snmp/
  sudo systemctl enable snmpd
  sudo systemctl restart snmpd
}

#update_repo
install_snmp_packages

