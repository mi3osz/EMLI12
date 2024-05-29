#!/bin/bash

general_logfile="/home/phub/project/main_log"

#-------------------------------REQUIREMENTS-----------------------------------

# Needs to have "python" and "opencv" installed system-wise
# sudo apt install python3-opencv

#-------------------------------REQUIREMENTS-----------------------------------

cd "/home/phub/project" #Go to project directory.
mkdir -p "temp" # Create directory for today's images if it doesn't exist
cd "temp"

#-------------------------------TIME TRIGGER PART -----------------------------------

# Background while loop for the Time images
(
  while true; do # Had to do it here because running take_photo.sh broke and we can't fix it :D
    echo "[MOTION-TIME-SCRIPT] Time Elapesed. Triggering Image." >> $general_logfile;
    export TRIG="Time"
    bash "/home/phub/project/take_photo.sh"  
    sleep 300

  done
) &

#-------------------------------TIME TRIGGER PART -----------------------------------


#-------------------------------MOTION TRIGGER PART -----------------------------------

while true; do

while [ -f "/tmp/wiping_in_progress" ]; do
  sleep 0.5
  echo "[MOTION-TIME-SCRIPT] Waiting for wiping to finish..." >> $general_logfile;
done
if [[ ! -f "test0.jpg" ]]; then # Check if there's already an image in today's folder
  rpicam-still -t 0.01 -o "test0.jpg" 2>/dev/null # Take first image
else
  rpicam-still -t 0.01 -o "test1.jpg" 2>/dev/null # Take subsequent images
  export MOTIONDATETIME=$(date "+%Y-%m-%d %H:%M:%S.%3N") #Takes the current date once
  motion_result=$(python3 "/home/phub/project/motiontrig.py" "test0.jpg" "test1.jpg") # Detect motion with cv2 motiontriq.py
fi

if [[ "$motion_result" == "Motion" ]]; then # If motion was detected run take_photo.sh 
  echo "[MOTION-TIME-SCRIPT] Motion Detected. Triggering image." >> $general_logfile;
  export TRIG="$motion_result"
  bash "/home/phub/project/take_photo.sh"

elif [[ "$motion_result" == "No_Motion" ]]; then # If no motion was detected replace old photo with current

  rm test0.jpg
  mv test1.jpg test0.jpg

fi

sleep 1

done

#-------------------------------MOTION TRIGGER PART -----------------------------------