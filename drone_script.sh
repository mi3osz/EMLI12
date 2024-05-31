#!/bin/bash


STATUS_FILE="/tmp/connection_status" # Temporary file to store connection status
echo "false" > "$STATUS_FILE" # assume drone not connected at start

WIFI_NAME="EMLI-TEAM-12"
WIFI_PASSWORD="whatever"  
log_file="cam1_wifi_logs.txt"
local_device_ip="192.168.10.1" 
image_path="/home/phub/project/images/" #path to images on RPI
received_path="/home/bot/Desktop/received/$WIFI_NAME" #where do we want to store the images on drone
mkdir -p "$received_path"

function force_connect() {
  nmcli dev wifi connect "$WIFI_NAME" password "$WIFI_PASSWORD"
  sleep 5
}

# Function to monitor and log WiFi, and update connection status
monitor_and_log_wifi() {
    
  # Define database and log file
  db_file="/home/bot/cam1wifi_logs.db"

  # Here we basically initialize the database
  sqlite3 "$db_file" <<EOF
CREATE TABLE IF NOT EXISTS wifi_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    epoch_time INTEGER NOT NULL,
    wifi_quality INTEGER NOT NULL,
    signal_level INTEGER NOT NULL
);
EOF

  while true; do

    if ping -c 1 "$local_device_ip" &> /dev/null; then # If connected, then log and update status
      echo "true" > "$STATUS_FILE"

      # Get epoch time
      epoch_time=$(date +%s)

      # Get WiFi quality and signal level
      wifi_info=$(iwconfig 2>/dev/null | grep "Signal\|Quality")
      if [[ -n "$wifi_info" ]]; then
        wifi_quality=$(echo "$wifi_info" | grep "Quality=" | awk -F'=' '{print $2}' | awk '{print $1}' | awk -F'/' '{print $1}')
        signal_level=$(echo "$wifi_info" | grep "Signal level" | awk '{print $4}' | awk -F'=' '{print $2}')
        
        # Log to the txt file
        echo "$epoch_time | WiFi Quality: $wifi_quality, Signal Level: $signal_level" >> "$log_file"

        # Insert data into the database
        sqlite3 "$db_file" <<EOF
INSERT INTO wifi_log (epoch_time, wifi_quality, signal_level)
VALUES ($epoch_time, $wifi_quality, $signal_level);
EOF
      fi
    else
      echo "false" > "$STATUS_FILE"
    fi
    sleep 1 #log every 1 second
  done
}

# Start monitoring and database log in the background
monitor_and_log_wifi &



while true; do

  connected=$(cat "$STATUS_FILE") #update connection status

  if nmcli dev wifi list | grep -q "$WIFI_NAME"; then #check if camera is in range

    while [ "$connected" == "true" ]; do

      echo "Connected to RPI. Beginning main program ..."

      #---- MAIN CODE ---- #

      laptop_date_time=$(date +"%Y-%m-%d %H:%M:%S") #retrieve date from drone. 
      # Send variable via SSH and sync time
      ssh phub@192.168.10.1 "sudo date -s '$laptop_date_time'"

      echo "Step 1. RPI Time synced with drone"

      if ! ping -c 2 $local_device_ip &> /dev/null; then # conenction check
        echo "Connection dropped after Step 1. Reconnecting..."
        echo "false" > "$STATUS_FILE"
        force_connect
        sleep 5
        break  # Exit the outer loop if ping fails
      else
        connected=$(cat "$STATUS_FILE")
      fi
      

      remote_file_time=$(ssh -i /home/bot/keynumber2 phub@$local_device_ip "stat -c %y /home/phub/project/imagelog_camera1.txt") #retrieve timestamp of log-file on RPI
      local_file_time=$(stat -c %y /home/bot/Desktop/received/logcam1.txt) #retrieve timestamp of log-file on laptop

      if [[ "$remote_file_time" > "$local_file_time" ]]; then #check if RPI log file is newer than laptop log file
        rsync -avz -e "ssh -i /home/bot/keynumber2" phub@$local_device_ip:/home/phub/project/imagelog_camera1.txt /home/bot/Desktop/received
        echo "Step 2. PI-LOG file copied from RPI to laptop"
        
        #BEGIN IMAGE TRANSFER

        : '
        1. Unpack copied filed.
        2. Check which images are new. 
        3. Start loop to copy new images. Start with the oldest timestamp (might be pending from previous transfer).
        4. Every time an image is succesfully downloaded, update own local file with new image name.
        5. Repeat loop until all new images are downloaded. 

        In case of transfer unsuccessful, ping and break if connection is lost.
        '

        new_file="/home/bot/Desktop/received/imagelog_camera1.txt"
        own_file="/home/bot/Desktop/received/logcam1.txt"

        differences=$(comm -23 "$new_file" "$own_file") #Found out if new file has new lines in comparison to own file

        # Check if there are differences (new lines)
        if [[ ! -z "$differences" ]]; then
          echo "New images to download"
          while [[ ! -z "$differences" ]]; do 

            while IFS= read -r line; do
              date_time=$(echo "$line" | cut -d '/' -f 1)
              name=$(echo "$line" | cut -d '/' -f 2)

              mkdir -p "$received_path/$date_time"

              if ! ping -c 2 $local_device_ip &> /dev/null; then # connenction check
                echo "Connection dropped after Step 2. Reconnecting..."
                echo "false" > "$STATUS_FILE"
                force_connect
                sleep 5
                break 2  # Exit two while loops
              fi

              scp -i "/home/bot/keynumber2" "phub@192.168.10.1:$image_path/$line.jpg" "$received_path/$date_time/" &&
              scp -i "/home/bot/keynumber2" "phub@192.168.10.1:$image_path/$line.json" "$received_path/$date_time/"

              if [[ $? -eq 0 ]]; then
                echo "Successfully Downloaded $name"
                echo "$line" >> "$own_file"

              else
                echo "Failed to download $name"
                break
              fi

            done <<< "$differences" #iterate through each line in differences


            # Check/update for differences again after downloading
            differences=$(diff "$new_file" "$own_file")

            # If no differences, break out of the outer loop
            if [[ -z "$differences" ]]; then

              # Update own file timestamp
              local_file_time=$(stat -c %y /home/bot/Desktop/received/logcam1.txt)
              break
            fi
            
          done
          
        fi

        
      echo "Step 3 completed. Drone has all new RPI images"
      sleep 5


      else
        echo "No new data to copy. Waiting..."
        sleep 5
      fi

    done

    echo "$(date +"%Y-%m-%d %H:%M:%S") - Disconnected from WiFi. Reconnecting..." #if connection is lost we output this message
    force_connect
    sleep 5
    

  else
    echo "RPI not in range. Waiting..." #if RPI not in range we output this message
    sleep 5

  fi


done #end of main loop
