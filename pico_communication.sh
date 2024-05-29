#!/bin/bash

# ================================
# This code will run the communication link between the Pico and MQTT. 
# Here it will receive the wipe command from the MQTT or message that it received rain.
# ================================

general_logfile="/home/phub/project/main_log"


# Settings for MQTT
mosquitto_user="my_user"
mosquitto_password="whatever"
mosquitto_port=1883  
mosquitto_broker="localhost"
  
# Settings for Serial:
serial_device="/dev/ttyACM0"


if [ ! -e "$serial_device" ]; then
    echo "Error: Serial device not found: $serial_device" >> $general_logfile;
    exit 1
fi

echo {'wiper_angle: 0'} > $serial_device

WAIT_FOR_WRITE="0"
stty -F "$serial_device" 115200
while true; do
  # Set the baud rate to 115200 (inside the loop for continuous configuration)
    while [ -f "/tmp/hold_serial" ]; do
        echo "[PICO-COM-SCRIPT] Waiting for wipe to read" >> $general_logfile;
        sleep 0.5;
    done
    
    
    read LINE < "$serial_device"
    if [[ "$LINE" == *'"rain_detect": 1'* ]]; then
        mosquitto_pub -h $mosquitto_broker -u $mosquitto_user -P $mosquitto_password -p $mosquitto_port -t "wiper_control/in" -m "RAIN";
    fi
    sleep 1.1 # Don't know why, but will give an json error for value <= 1.1
done &
pico_serial_ID=$!
# Start the MQTT Subscriber, for testing currently set to the trigger one :D
  mosquitto_sub -t "wiper_control/out" \
    -h $mosquitto_broker -u $mosquitto_user -P $mosquitto_password -p $mosquitto_port | while read -r msg; do
    echo "[PICO-COM-SCRIPT] New command received: $msg" >> $general_logfile;
      if [[ "$msg" == "WIPE" ]]; then
        echo "[PICO-COM-SCRIPT] Starting Wipe." >> $general_logfile;
        touch "/tmp/hold_serial"
        sleep 1.5 # Wait for the read to stop reading.
        echo {'wiper_angle: 180'} > $serial_device
        sleep 0.4
        echo {'wiper_angle: 0'} > $serial_device
        sleep 1.5
        echo "[PICO-COM-SCRIPT] Done Wipe" >> $general_logfile;
        rm "/tmp/hold_serial"  2>/dev/null 
        mosquitto_pub -h $mosquitto_broker -u $mosquitto_user -P $mosquitto_password -p $mosquitto_port -t "wiper_control/in" -m "DONE"
      fi
  done &
  pico_mqtt_ID=$!

echo "[PICO-COM-SCRIPT] The script was started with its background function ($pico_serial_ID and $pico_mqtt_ID). us 'fg' to bring the background function forward."
echo "[PICO-COM-SCRIPT] Type 'exit' to close the program"
  # Use a while loop to keep the program running until exit is typed
while true; do
  # Read user input
  read -r userInput

  # Check if input matches "exit" (case-insensitive)
  if [[ "$userInput" == "exit" || "$userInput" == "EXIT" ]]; then
    kill $pico_serial_ID
    kill $pico_mqtt_ID
    break
  else
    # Input doesn't match "exit", prompt the user
    echo "[PICO-COM-SCRIPT] Type 'exit' to close the program."
  fi
done

# Script execution ends here after the loop exits
echo "Program terminated."
