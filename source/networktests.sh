#!/usr/bin/env bash

#############################
###DECLARING VARIABLES#######
today=`date '+%Y-%m-%d'`
filename="./tests_${today}"
sourceip=`curl -s ipaddr.ovh`
iface=`ip route show default | awk '/default/ {print $5}'`
sourcemac=`cat /sys/class/net/${iface}/address`

declare -A locations=(
  [1]="Roubaix,FR|rbx.proof.ovh.net"
  [2]="Gravelines.FR|gra.proof.ovh.net"
  [3]="Strathbourg.FR|sbg.proof.ovh.net"
  [4]="Beauharnois,CA|bhs.proof.ovh.ca"
  [5]="Mumbai,IN|bom.proof.ovh.net"
  [6]="Vint Hill,USA|vin.proof.ovh.us"
  [7]="Hilsboro, USA|gil.proof.ovh.us")
#############################



read -p "Please provide the destination IP (remote machine): " ip

echo "Available Locations:"
for key in $(echo "${!locations[@]}" | tr ' ' '\n' |sort -n); do
	location=$(echo "${locations[$key]}" | cut -d '|' -f 1)
	echo "$key) $location"
done

read -p "Choose the location nearest your server (1-7): " location_choice

if ! [[ "$location_choice" =~ ^[1-7]$ ]]; then
	echo "Invalid location choice."
	exit 1
fi

url=$(echo "${locations[$location_choice]}" | cut -d '|' -f 2)

touch "${filename}.txt"
echo "Source IP: " $sourceip >> ${filename}.txt
echo "Source MAC: " $sourcemac >> ${filename}.txt
echo "Destination IP:" $ip >> ${filename}.txt
echo "" >> ${filename}.txt

echo "Running Ping tests to $url"
echo "Ping test to $url" >> ${filename}.txt
ping -c 10 $url >> ${filename}.txt
echo "Done"
echo "" >> ${filename}.txt

echo "Running MTR Test"
echo "MTR from Source to Destination: " >> ${filename}.txt
mtr -o 'J M X LSR NA B W V' -wzbc 50 $ip >> ${filename}.txt
echo "Done"
echo "" >> ${filename}.txt

echo "Running Iperf TCP tests"
echo "IPERF TCP" >> ${filename}.txt
iperf3 -c $url -i 2 -t 20 -P 5 -4 -p 5204 >> ${filename}.txt
echo "Done"
echo "" >> ${filename}.txt

echo "Running Iper3 UDP tests"
echo "IPERF UDP" >> ${filename}.txt
iperf3 -c $url -i 1 -u -t 30 -p 5205 >> ${filename}.txt
echo "Done"
echo "" >> ${filename}.txt

echo "Running wget test"
echo "This will take a few minutes"
url2="https://${url}/files/10Gb.dat"
echo "Results of wget to $url2" >> ${filename}.txt
wget_output=$(wget -O /dev/null --report-speed=bits $url2 2>&1)
speed=$(echo $wget_output | grep -oP '\d+\s+[KM]?b/s')
echo
echo "$speed" >> ${filename}.txt
echo"Done"
echo "" >> ${filename}.txt

echo "Getting interface statistics"
echo "Results of ethtool on interface $iface" >> ${filename}.txt
etherror=$(ethtool -S $iface | grep error)
echo $etherror >> ${filename}.txt
echo "Done"

echo "All tests complete"
echo "A file named ${filename}.txt has been placed in the current working directory."
echo "Please send this in response to your ticket! "

