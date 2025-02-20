#!/bin/bash

function db_credentials()
{
ip_add=192.168.1.59
db_name="IP_INFORMATION"
db_pass="Cottons@1327"
system_ip=$(ifconfig | grep 192.168.1 | awk '{print $2 " "}')
db_host=$(echo $system_ip | tr '.' '_')
db_hostname="AI_AGENT"
#echo $db_hostname
}

function table_creation()
{
  mysql -u root --password=$db_pass $db_name -h $ip_add -e "CREATE TABLE $db_hostname(IP VARCHAR(255), PRIORITY INT(3), SERVICE VARCHAR(255), AVG_RX FLOAT, AVG_TX FLOAT);"
}

function AI_Agent_data()
{
  mapfile -t data < results.txt
#  echo "${result[@]}"
#  echo ""
#  echo "Truncating the database table..."
#  mysql -u root --password=$db_pass $db_name -h $ip_add -e "TRUNCATE $db_hostname;"
#  echo "Done"

  mysql -u root --password=$db_pass $db_name -h $ip_add -e "INSERT INTO AI_AGENT(IP,PRIORITY,SERVICE,AVG_RX,AVG_TX) VALUES('$system_ip','${data[3]}','${data[2]}','${data[0]}','${data[1]}');"

}

db_credentials
#table_creation
AI_Agent_data
