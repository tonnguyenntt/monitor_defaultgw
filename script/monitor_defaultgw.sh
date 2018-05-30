#!/bin/bash

PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

logfile="/var/log/monitor-defaultgw.log"
host=$(hostname -f)

SOURCE_IP=10.22.140.15
DEST_IP=8.8.8.8

ADNFWVN01_IP=10.22.140.2
ADNFWVN01_MAC=f8:c2:88:1b:82:9e
ADNFWVN01_ISP="VNPT"

ADNFWVN02_IP=10.22.140.4
ADNFWVN02_MAC=60:73:5c:98:78:b5
ADNFWVN02_ISP="Viettel"

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


test -f $logfile && cat /dev/null > $logfile || touch $logfile
exec &> >(tee -a "$logfile")
while true
do
  echo "Date time: $(date)"
  echo "Host: $host"

  current_gw=$(currentGW)
  status_viettel=$(checkGW2Internet "$ADNFWVN02_MAC")
  status_vnpt=$(checkGW2Internet "$ADNFWVN01_MAC")

  if [ $status_viettel == 0 ] && [ "$current_gw" ==  "$ADNFWVN02_IP" ]
  then
    echo "Status: Gateway is STILL to $ADNFWVN02_ISP(primary)"
    echo "Current GW: $current_gw"
  elif [ $status_viettel == 1 ] && [ $status_vnpt == 0 ] && [ "$current_gw" != "$ADNFWVN01_IP" ]
  then
    switchGW "$ADNFWVN02_IP" "$ADNFWVN01_IP"
    echo "Status: Gateway is SWITCHED to $ADNFWVN01_ISP(secondary)"
    echo "Reason: $ADNFWVN02_ISP is down!"
    echo "Current GW: $(currentGW)"
  elif [ $status_viettel == 0 ] && [ "$current_gw" != "$ADNFWVN02_IP" ]
  then
    switchGW "$ADNFWVN01_IP" "$ADNFWVN02_IP"
    echo "Status: Gateway is now BACK to $ADNFWVN02_ISP(primary)"
    echo "Current GW: $(currentGW)"
  else
    echo "Status: Please check the previous message!!!"
    echo "Current GW: $current_gw"
  fi
  echo "==============================================="
  sleep 60
done
