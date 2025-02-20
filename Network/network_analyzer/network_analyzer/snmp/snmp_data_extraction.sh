#!/bin/bash

VM_IPS=("192.168.1.18" "192.168.1.220")
#LXC_IPS=("192.168.1.59" "192.168.1.79" "192.168.1.99" "192.168.1.111" "192.168.1.112")
LXC_IPS=("192.168.1.79" "192.168.1.99")

db_connect_info()
{
ip_add="192.168.1.59"
db_name="IP_INFORMATION"
db_pass="Cottons@1327"
system_hostname=$(hostname)
db_hostname=$(echo $system_hostname | sed 's/-/_/g')
}

db_cleanup()
{
mysql -h $ip_add -u root --password=$db_pass $db_name -e "TRUNCATE VM_LXC_IPS"
}

machine_oid_info_vms()
{
OID_TOTAL_RAM="1.3.6.1.4.1.2021.4.5.0"
OID_CACHE_RAM="1.3.6.1.4.1.2021.4.15.0"
OID_BUFFER_RAM="1.3.6.1.4.1.2021.4.14.0"
OID_ROOT_PART_NAME_VM="1.3.6.1.2.1.25.2.3.1.3.36"
OID_DISK_ALLOCATION_UNITS_VM="1.3.6.1.2.1.25.2.3.1.4.36"
OID_PART_TOTAL_SPACE_VM="1.3.6.1.2.1.25.2.3.1.5.36"
OID_PART_USED_SPACE_VM="1.3.6.1.2.1.25.2.3.1.6.36"
OID_CPU_COUNT_VM="1.3.6.1.2.1.25.3.2.1.3"
OID_CPU_IDLE_VM="1.3.6.1.4.1.2021.11.11.0"
OID_USER_CONNECTIONS="1.3.6.1.2.1.25.1.5.0"
OID_SYSTEM_PROCESSES="1.3.6.1.2.1.25.1.6.0"
OID_SYSTEM_UPTIME="1.3.6.1.2.1.25.1.1.0"
}

machine_oid_info_lxc()
{
system_hostname=$(hostname)
db_hostname=$(echo $system_hostname | sed 's/-/_/g')
OID_TOTAL_RAM="1.3.6.1.4.1.2021.4.5.0"
OID_CACHE_RAM="1.3.6.1.4.1.2021.4.15.0"
OID_BUFFER_RAM="1.3.6.1.4.1.2021.4.14.0"
OID_ROOT_PART_NAME_LXC="1.3.6.1.2.1.25.2.3.1.3.31"
OID_DISK_ALLOCATION_UNITS_LXC="1.3.6.1.2.1.25.2.3.1.4.31"
OID_PART_TOTAL_SPACE_LXC="1.3.6.1.2.1.25.2.3.1.5.31"
OID_PART_USED_SPACE_LXC="1.3.6.1.2.1.25.2.3.1.6.31"
OID_CPU_COUNT_LXC="1.3.6.1.2.1.25.3.2.1.3"
OID_CPU_IDLE_LXC="1.3.6.1.4.1.2021.11.11.0"
OID_USER_CONNECTIONS="1.3.6.1.2.1.25.1.5.0"
OID_SYSTEM_PROCESSES="1.3.6.1.2.1.25.1.6.0"
OID_SYSTEM_UPTIME="1.3.6.1.2.1.25.1.1.0"
}

machine_ram_info()
{
TOTAL_SYSTEM_RAM=$(snmpwalk -v1 -c aniket $IP $OID_TOTAL_RAM | awk '{print $NF / 1024}')
TOTAL_CACHE_RAM=$(snmpwalk -v1 -c aniket $IP $OID_CACHE_RAM | awk '{print $NF / 1024}')
TOTAL_BUFFER_RAM=$(snmpwalk -v1 -c aniket $IP $OID_BUFFER_RAM | awk '{print $NF / 1024}')
TOTAL_USED_RAM=$(echo "$TOTAL_SYSTEM_RAM - $TOTAL_CACHE_RAM - $TOTAL_BUFFER_RAM" | bc)
TOTAL_FREE_RAM=$(echo "$TOTAL_SYSTEM_RAM - ${TOTAL_USED_RAM#-}" | bc)
}

machine_disk_info_vms()
{
DISK_PART_NAME=$(snmpwalk -v1 -c aniket $IP $OID_ROOT_PART_NAME_VM | awk '{gsub(/"/, "");print $4 "\t"}')
DISK_PART_ALLOCATION_UNITS=$(snmpwalk -v1 -c aniket $IP $OID_DISK_ALLOCATION_UNITS_VM | awk '{print $4 "\t"}')
DISK_PART_TOTAL_SPACE=$(snmpwalk -v1 -c aniket $IP $OID_PART_TOTAL_SPACE_VM | awk '{print $4 "\t"}')
DISK_PART_USED_SPACE=$(snmpwalk -v1 -c aniket $IP $OID_PART_USED_SPACE_VM | awk '{print $4 "\t"}')
FINAL_TOTAL_PART=$(echo "scale=2; ($DISK_PART_TOTAL_SPACE * $DISK_PART_ALLOCATION_UNITS / 1024/1024/1024)" | bc)
USED_TOTAL_PART=$(echo "scale=2; ($DISK_PART_USED_SPACE * $DISK_PART_ALLOCATION_UNITS / 1024/1024/1024)" | bc)
FREE_DISK_PART=$(echo "scale=2; ($FINAL_TOTAL_PART - $USED_TOTAL_PART)" | bc)
DISK_USED_PERCENT=$(echo "scale=2; ($USED_TOTAL_PART / $FINAL_TOTAL_PART * 100)" | bc)
DISK_FREE_PERCENT=$(echo "scale=2; (100-$DISK_USED_PERCENT)" | bc)
}

machine_disk_info_lxc()
{
DISK_PART_NAME=$(snmpwalk -v1 -c aniket $IP $OID_ROOT_PART_NAME_LXC | awk '{gsub(/"/, "");print $4 "\t"}')
DISK_PART_ALLOCATION_UNITS=$(snmpwalk -v1 -c aniket $IP $OID_DISK_ALLOCATION_UNITS_LXC | awk '{print $4 "\t"}')
DISK_PART_TOTAL_SPACE=$(snmpwalk -v1 -c aniket $IP $OID_PART_TOTAL_SPACE_LXC | awk '{print $4 "\t"}')
DISK_PART_USED_SPACE=$(snmpwalk -v1 -c aniket $IP $OID_PART_USED_SPACE_LXC | awk '{print $4 "\t"}')
FINAL_TOTAL_PART=$(echo "scale=2; ($DISK_PART_TOTAL_SPACE * $DISK_PART_ALLOCATION_UNITS / 1024/1024/1024)" | bc)
USED_TOTAL_PART=$(echo "scale=2; ($DISK_PART_USED_SPACE * $DISK_PART_ALLOCATION_UNITS / 1024/1024/1024)" | bc)
FREE_DISK_PART=$(echo "scale=2; ($FINAL_TOTAL_PART - $USED_TOTAL_PART)" | bc)
DISK_USED_PERCENT=$(echo "scale=2; ($USED_TOTAL_PART / $FINAL_TOTAL_PART * 100)" | bc)
DISK_FREE_PERCENT=$(echo "scale=2; (100-$DISK_USED_PERCENT)" | bc)
}

machine_cpu_info_vms()
{
CPU_CORES=$(snmpwalk -v1 -c aniket $IP $OID_CPU_COUNT_VM | grep "Genuine" | wc -l)
CPU_IDLE_PERCENT=$(snmpwalk -v1 -c aniket $IP $OID_CPU_IDLE_VM | awk '{print $4}')
CPU_USED_PERCENT=$(echo "scale=2; (100-$CPU_IDLE_PERCENT)" | bc)
#CPU_USED_PERCENT=0
}

machine_cpu_info_lxc()
{
CPU_CORES=$(snmpwalk -v1 -c aniket $IP $OID_CPU_CORES | grep "Genuine" | wc -l)
CPU_IDLE_PERCENT=$(snmpwalk -v1 -c aniket $IP $OID_CPU_IDLE_LXC | awk '{print $4}')
CPU_USED_PERCENT=$(echo "scale=2; (100-$CPU_IDLE_PERCENT)" | bc)
#CPU_USED_PERCENT=0
}

machine_system_info()
{
TOTAL_USERS=$(snmpwalk -v1 -c aniket $IP $OID_USER_CONNECTIONS | awk '{print $NF "\t"}')
TOTAL_SYSTEM_PROCESSES=$(snmpwalk -v1 -c aniket $IP $OID_SYSTEM_PROCESSES | awk '{print $NF "\t"}')
SYSTEM_UPTIME=$(snmpwalk -v1 -c aniket $IP $OID_SYSTEM_UPTIME | awk '{print $NF "\t"}')
}

machine_print_info()
{
echo ""
echo " ***** IP ADDRESS *****"
echo "IP_ADDRESS: "$IP
echo " ***** MEMORY INFORMATION ***** "
echo "Total Ram in the System:" $TOTAL_SYSTEM_RAM "MB"
echo "Total Ram Used in the System:" ${TOTAL_USED_RAM#-} "MB"
echo "Total Ram Free in the System:" $TOTAL_FREE_RAM "MB"
echo " ***** DISK PARTITION INFORMATION ***** "
echo "Partition: "$DISK_PART_NAME "(root)"
echo "Total Partition Space: "$FINAL_TOTAL_PART "GB"
echo "Partition Used: "$USED_TOTAL_PART "GB"
echo "Partition Free: "$FREE_DISK_PART "GB"
echo "Used %: "$DISK_USED_PERCENT
echo "Free %: "$DISK_FREE_PERCENT
echo " ***** CPU UTILIZATION ***** "
echo "Number of CPUs: "$CPU_CORES
echo "CPU Idle Percent: "$CPU_USED_PERCENT"%"
echo " ***** SYSTEM INFORMATION ***** "
echo "Number of User Connections to Machine: "$TOTAL_USERS
echo "Total Number of Processes: "$TOTAL_SYSTEM_PROCESSES
echo "System Uptime: "$SYSTEM_UPTIME
echo ""
}

info_db_upload()
{
  mysql -h $ip_add -u root --password=$db_pass $db_name -e "  INSERT INTO VM_LXC_IPS(IP,TOTAL_RAM,USED_RAM,FREE_RAM,DISK_PART,TOTAL_DISK_PART,DISK_PART_USED,DISK_PART_FREE,PART_USED_PERCENT,PART_FREE_PERCENT,CPU_NUM,CPU_USED_PERCENT,NUM_PROCESSES,UPTIME,NUM_CONNECT) VALUES('$IP','$TOTAL_SYSTEM_RAM','$TOTAL_USED_RAM','$TOTAL_FREE_RAM','$DISK_PART_NAME','$FINAL_TOTAL_PART','$USED_TOTAL_PART','$FREE_DISK_PART','$DISK_USED_PERCENT','$DISK_FREE_PERCENT','$CPU_CORES','$CPU_USED_PERCENT','$TOTAL_SYSTEM_PROCESSES','$SYSTEM_UPTIME','$TOTAL_USERS');"
}

db_connect_info
db_cleanup

for IP in "${VM_IPS[@]}"; do
    db_connect_info
    machine_oid_info_vms
    machine_ram_info
    machine_disk_info_vms
    machine_cpu_info_vms
    machine_system_info
    machine_print_info
    info_db_upload
done

for IP in "${LXC_IPS[@]}"; do
    db_connect_info
    machine_oid_info_lxc
    machine_ram_info
    machine_disk_info_lxc
    machine_cpu_info_lxc
    machine_system_info
    machine_print_info
    info_db_upload
done
