#!/bin/bash

general_logfile="/home/phub/project/main_log"

# Mosquitto subscriber script for "/remote-trigger/1/out" topic with optional authentication

# Edit the following section with your Mosquitto broker details (if required)
# Leave username, password and port blank if not using authentication
mosquitto_user="my_user"
mosquitto_password="whatever"
mosquitto_port=1883  # Default port for Mosquitto

# Edit the following to match your broker's address
mosquitto_broker="localhost"

# Subscribe to the topic
mosquitto_sub -t "remote-trigger/1/out" \
  -h $mosquitto_broker -u $mosquitto_user -P $mosquitto_password -p $mosquitto_port  \
  -v  | while read -r msg; do
    echo "[EXTERNAL-TRIGGER-MQTT] New msg received: $msg" >> $general_logfile;
    if [[ "$msg" == *'TRIGGE'* ]]; then
      export TRIG="External" # Exports trigger word "External"
      bash "/home/phub/project/take_photo.sh" # Runs take_photo.sh
    fi
done
