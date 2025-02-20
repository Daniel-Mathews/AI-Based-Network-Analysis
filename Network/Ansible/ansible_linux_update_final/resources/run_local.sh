#!/bin/bash

function hostname_db_mysql
{
ip_add=192.168.1.59
db_name="IP_INFORMATION"
db_pass="Cottons@1327"
system_hostname=$(ifconfig | grep 192.168.1 | awk '{print $2}')
db_host=$(echo $system_hostname | tr '.' '_')
db_hostname="IP_$db_host"
echo $db_hostname
}

function table_creation
{
  mysql -u root --password=$db_pass $db_name -h $ip_add -e "CREATE TABLE $db_hostname(PACKAGE_NAME VARCHAR(255),PACKAGE_VERSION VARCHAR(255));"
}

function folder_creation
{
  echo "Making /package_db in the user home directory"
  mkdir /home/$USER/package_db_raw_data
  echo ""
}

function file_generation
{
  echo "Recording all the dpkg packages in *package.txt* file..."
  dpkg -l > /home/$USER/package_db_raw_data/package.txt
  echo ""
}

function package_file_separation
{
  echo "Making Separate *package_name.txt* and *package_version.txt* files..."
  awk 'NR>5 {print $2 "\t"}' /home/$USER/package_db_raw_data/package.txt > /home/$USER/package_db_raw_data/package_name.txt
  awk 'NR>5 {print $3 "\t"}' /home/$USER/package_db_raw_data/package.txt > /home/$USER/package_db_raw_data/package_version.txt
  echo ""
  echo "Checking for any count difference, if not - the script will proceed..."
  echo ""
  package_name_count=$(wc -l /home/$USER/package_db_raw_data/package_name.txt | awk '{print $1 " "}')
  package_version_count=$(wc -l /home/$USER/package_db_raw_data/package_version.txt | awk '{print $1 " "}')
  if [[ $package_name_count != $package_version_count ]]
  then
    echo "Package_Name and Package_Version - Count is not equal, Exiting...."
    exit '1';
  fi
}

function database_push
{
  package_name=($(cat /home/$USER/package_db_raw_data/package_name.txt))
  array_size=${#package_name[@]}
  package_version=($(cat /home/$USER/package_db_raw_data/package_version.txt))
  array_size_version=${#package_version[@]}

<< comment
This for loop will be used to display the version of the packages
***NOTE****: Make sure the tables with the name of the VM has been created in the database, before running
the SQL part of this script.

comment

echo ""
echo "Truncating the database table..."
mysql -u root --password=$db_pass $db_name -h $ip_add -e "TRUNCATE $db_hostname;"
echo "Done"

echo ""
echo "Inserting the values into the respective database..."
echo ""

for ((i=0;i<=$array_size;i++))
do
  mysql -u root --password=$db_pass $db_name -h $ip_add -e "INSERT INTO $db_hostname(PACKAGE_NAME,PACKAGE_VERSION) VALUES('${package_name[i]}','${package_version[i]}');"
done

echo ""
echo "Insertion process completed!"
echo ""

}

hostname_db_mysql
table_creation
folder_creation
file_generation
package_file_separation
database_push
