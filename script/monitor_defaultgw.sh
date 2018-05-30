#!/bin/bash

PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

logfile="/var/log/monitor-defaultgw.log"
host=$(hostname -f)

function currentGW
{
  current_gw=$(ip route | head -n1 | grep -Po 'default\ via\ \K[0-9]{1,3}(.[0-9]{1,3}){3}')
  echo $current_gw
}


function checkGW2Internet
{
  sum_fail=0 
  for i in {1..2}
  do 
    nping_result=$(nping -q --icmp --count 10 --source-ip $SOURCE_IP --dest-mac $1 $DEST_IP | grep -Po 'Lost:\ \K[0-9]{1,2}')
    sum_fail=$((sum_fail + nping_result))
    sleep 3
  done
  test "$sum_fail" -gt 10 && echo 1 || echo 0
}


function switchGW
{
  gw_old=$1
  gw_new=$2

  route delete default gw $gw_old &> /dev/null
  route add default gw $gw_new &> /dev/null
}


if [ ! -f "$1" ]
then
  echo "Please provide a valid conf file for input!"
  exit 1
else
  source "$1"
fi

test -f $logfile && cat /dev/null > $logfile || touch $logfile
exec &> >(tee -a "$logfile")
while true
do
  echo "Date time: $(date)"
  echo "Host: $host"

  current_gw=$(currentGW)
  gw01_toInternet=$(checkGW2Internet "$GW01_MAC")
  gw02_toInternet=$(checkGW2Internet "$GW02_MAC")

  if [ $gw01_toInternet == 0 ] && [ "$current_gw" ==  "$GW01_IP" ]
  then
    echo "Status: Gateway is STILL to $GW01_ISP(primary)"
    echo "Current GW: $current_gw"
  elif [ $gw01_toInternet == 1 ] && [ $gw02_toInternet == 0 ] && [ "$current_gw" != "$GW02_IP" ]
  then
    switchGW "$GW01_IP" "$GW02_IP"
    echo "Status: Gateway is SWITCHED to $GW02_ISP(secondary)"
    echo "Reason: $GW01_ISP is down!"
    echo "Current GW: $(currentGW)"
  elif [ $gw01_toInternet == 0 ] && [ "$current_gw" != "$GW01_IP" ]
  then
    switchGW "$GW02_IP" "$GW01_IP"
    echo "Status: Gateway is now BACK to $GW01_ISP(primary)"
    echo "Current GW: $(currentGW)"
  else
    echo "Status: Please check the previous message!!!"
    echo "Current GW: $current_gw"
  fi
  echo "==============================================="
  sleep 60
done
