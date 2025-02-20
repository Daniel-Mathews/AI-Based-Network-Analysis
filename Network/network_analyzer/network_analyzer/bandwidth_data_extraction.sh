#!/bin/bash

function raw_data_extraction
{
  time_interval=1
  frequency=5
  sar -n DEV $time_interval $frequency > /home/$USER/network_analyzer/sar_raw_data.txt
  cat /home/$USER/network_analyzer/sar_raw_data.txt | grep ens > /home/$USER/network_analyzer/interface_raw_data.txt
}

function interface_data
{
  #sar -n DEV 60 60 | grep ens > /home/$USER/network_analyzer/interface_raw_data.txt
  head -n -1 /home/$USER/network_analyzer/interface_raw_data.txt > /home/$USER/network_analyzer/interface_data.txt
  awk '{printf "%-20s %-15s %-15s\n", $1" "$2, $7, $8}' interface_data.txt > /home/$USER/network_analyzer/final_data.txt
  sed -i "1i TIMESTAMP            rxkB/s          txkB" /home/$USER/network_analyzer/final_data.txt
}

function bandwidth_data_manipulation
{
  raw_recieving_bandwidth=($(awk '{print $7 "\t"}' /home/$USER/network_analyzer/interface_data.txt))
  raw_transmission_bandwidth=($(awk '{print $8 "\t"}' /home/$USER/network_analyzer/interface_data.txt))

  recieving_bandwidth_count=${#raw_recieving_bandwidth[@]}
  transmission_bandwidth_count=${#raw_transmission_bandwidth[@]}

  sum_recieving_bandwidth=0.0
  sum_transmission_bandwidth=0.0

  for i in ${raw_recieving_bandwidth[@]}
  do
    sum_recieving_bandwidth=$(echo "$sum_recieving_bandwidth + $i" | bc)
  done

  for j in ${raw_transmission_bandwidth[@]}
  do
    sum_transmission_bandwidth=$(echo "$sum_transmission_bandwidth + $j" | bc)
  done
  echo " " >> /home/$USER/network_analyzer/final_data.txt
  #echo "Total Recieving Bandwidth: "$sum_recieving_bandwidth >> /home/$USER/network_analyzer/final_data.txt
  #echo "Total Transmission Bandwidth: "$sum_transmission_bandwidth >> /home/$USER/network_analyzer/final_data.txt
  echo "($sum_recieving_bandwidth,$sum_transmission_bandwidth)" > /home/$USER/network_analyzer/sum_final_data.txt
}

raw_data_extraction
interface_data
bandwidth_data_manipulation
