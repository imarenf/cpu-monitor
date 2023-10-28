#!/bin/bash

API_URL=${1:-""}
MAX_CPU_ALLOWED=${2:-""}

send_alarm() {
  local response
  response=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H 'Content-Type: application/json' -d "{\"message\": \"alarm\"}" "$API_URL")

  if [ "$response" != "200" ]; then
    echo "Failed to send alarm to $API_URL: HTTP $response"
    return 1
  fi

  echo "Alarm sent successfully"
  return 0
}

if ! [ -x "$(command -v curl)" ]; then
  sudo apt-get update; sudo apt-get install curl -y
fi

while true; do
   current_cpu=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1) {u1=u; t1=t;} else print ($2+$4-u1) * 100 / (t-t1);}' \
               <(grep 'cpu ' /proc/stat) <(sleep 1; grep 'cpu ' /proc/stat))
   echo "Current CPU usage - $current_cpu%"
   if [ -n "$MAX_CPU_ALLOWED" ] && [[ "${current_cpu%.*}" -gt "$MAX_CPU_ALLOWED" ]]; then
     echo "CPU rate limit exceeded, sending notify"
     send_alarm "$API_URL"
     break
   fi
   sleep 5
done


