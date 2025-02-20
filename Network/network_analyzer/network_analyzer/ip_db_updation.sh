#!/bin/bash

function mysql_data
{
  USER="aniket"
  ip_add=192.168.1.59
  db_user="root"
  db_name="IP_INFORMATION"
  db_table_name="IP_INFO"
  db_pass="Cottons@1327"
}

function ip_raw_data
{
  sudo timeout 30 netdiscover -r 192.168.1.0/24 -P  > /home/$USER/network_analyzer/raw_ip_log.txt
}

function ip_data_upload
{
  status_up="UP"
  status_down="DOWN"
  ip_address=($(awk 'NR>3 {print $1 "\t"}' /home/$USER/network_analyzer/raw_ip_log.txt))
  mac_address=($(awk 'NR>3 {print $2 "\t"}' /home/$USER/network_analyzer/raw_ip_log.txt))
  size_ip_address=${#ip_address[@]}
  size_mac_address=${#mac_address[@]}

  echo "Truncating the database table..."
  mysql -u $db_user --password=$db_pass $db_name -h $ip_add -e "TRUNCATE $db_table_name;"

  for ((i=0;i<$size_ip_address;i++))
  do
    mysql -u $db_user --password=$db_pass $db_name -h $ip_add -e "INSERT INTO $db_table_name(IP_ADDRESS,MAC_ADDRESS) VALUES('${ip_address[i]}','${mac_address[i]}');"
  done


  for ((i=0;i<$size_ip_address;i++))
  do
  ping -c 1 ${ip_address[i]} > /dev/null 2>&1
  status=$?
  if [[ $status -eq 0 ]]; then
    mysql -u $db_user --password=$db_pass $db_name -h $ip_add -e "UPDATE $db_table_name SET STATUS='$status_up' WHERE IP_ADDRESS='${ip_address[i]}';"
  else
    mysql -u $db_user --password=$db_pass $db_name -h $ip_add -e "UPDATE $db_table_name SET STATUS='$status_down' WHERE IP_ADDRESS='${ip_address[i]}';"
  fi
  done

  echo ""
  echo "Insertion Process Completed!"
  echo ""
}

mysql_data
ip_raw_data
ip_data_upload
