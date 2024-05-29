#!/bin/bash

general_logfile="/home/phub/project/main_log"

echo "[WIPER-CONTROL-SCRIPT] Wiper control script started" >> $general_logfile;
FLAG_FILE="/tmp/wiping_in_progress" # Flag file stops raspi from taking images while wiper is wiping


# Settings for MQTT
mosquitto_user="my_user"
mosquitto_password="whatever"
mosquitto_port=1883  
mosquitto_broker="localhost"


  mosquitto_sub -t "wiper_control/in" \
    -h $mosquitto_broker -u $mosquitto_user -P $mosquitto_password -p $mosquitto_port | while read -r msg; do
    echo "[WIPER-CONTROL-SCRIPT]  $msg" >> $general_logfile;
      if [[ "$msg" == "RAIN" ]]; then
        echo "[WIPER-CONTROL-SCRIPT] Placing Flag File" >> $general_logfile;
        touch "$FLAG_FILE";
        sleep 0.2;
        mosquitto_pub -h $mosquitto_broker -u $mosquitto_user -P $mosquitto_password -p $mosquitto_port -t "wiper_control/out" -m "WIPE";
      elif [[ "$msg" == "DONE" ]]; then
        echo "[WIPER-CONTROL-SCRIPT] Getting rid of the flag file" >> $general_logfile;
        rm "$FLAG_FILE" 2>/dev/null;  # Remove the flag file once wiping is done 2>/dev/null is a way of removing errors outputted from this command(file not found)
      fi
  done 

