#!/bin/bash

#-------------------------------REQUIREMENTS-----------------------------------

# Needs to have "exiftool" and "jq" installed system-wise

#-------------------------------REQUIREMENTS-----------------------------------

general_logfile="/home/phub/project/main_log"

if [[ -z "$TRIG" ]]; then # if the script is run without exporting a the variable TRIG it assumes it is "Time" trigger
    trigger="Time"
else
    trigger="$TRIG"
fi


current_datetime=$(date "+%Y-%m-%d %H:%M:%S.%3N") # Gets the current date once so milliseconds dont differ

current_date=$(date -d "$current_datetime" "+%Y-%m-%d") # Takes date format out of current date string
timestamp=$(date -d "$current_datetime" "+%H%M%S_%3N")  # Takes timestamp format out of current date string
seconds_epoch=$(date -d "$current_datetime" +"%s.%3N")  # Takes seconds_epoch format out of current date string

cd "/home/phub/project" #Go to project directory.
mkdir -p "images" # Create images directory with today's date if it doesn't exist
cd "/home/phub/project/images"
mkdir -p "$current_date" # Create directory with today's date if it doesn't exist
cd "$current_date" # Moves into today's date directory

while [ -f "/tmp/wiping_in_progress" ]; do
  sleep 0.5
  echo "[TAKE-PHOTO-SCRIPT] Waiting for wiping to finish..." >> $general_logfile;
done

#-------------------------------GENERATING IMAGE PART-----------------------------------
image_file="$timestamp.jpg"

if [ "$trigger" = "Motion" ]; then
    echo "[TAKE-PHOTO-SCRIPT] Motion Trigger Saving Image" >> $general_logfile; 
    current_date=$(date -d "$MOTIONDATETIME" "+%Y-%m-%d") # Rewrites date format out of motion detection output string
    timestamp=$(date -d "$MOTIONDATETIME" "+%H%M%S_%3N")  # Rewrites timestamp format out of motion detection output string
    seconds_epoch=$(date -d "$MOTIONDATETIME" +"%s.%3N")  # Rewrites seconds_epoch format out of motion detection output string
    image="/home/phub/project/temp/test1.jpg" # If Motion trigger, use image from motion detection func
    image_file="$timestamp.jpg"
    cp "$image" "$image_file"
    mv "$image" "/home/phub/project/temp/test0.jpg" # change latest motion detection image to be the test image for next iteration 


else
    echo "[TAKE-PHOTO-SCRIPT] External/Time Trigger Saving Image" >> $general_logfile; 
    rpicam-still -t 0.01 -o "$image_file" #2>/dev/null # Take a new image without printing the info to terminal

fi  


#-------------------------------GENERATING IMAGE PART-----------------------------------


#-------------------------------GENERATING JSON FILE PART-----------------------------------

json_file="$timestamp.json"
tmp_json_file="$timestamp-tmp.json"

# Generates a .json file with the same name as the image into the current date folder
# Add arguments from exiftool outputs to add them into .json file
echo "[TAKE-PHOTO-SCRIPT] Generating JSON" >> $general_logfile; 
exiftool -json -SubjectDistance -ExposureTime -ISO -FileAccessDate $image_file > $json_file

# Adds the trigger and seconds epoch to the json
jq --arg trigger "$trigger" --argjson epoch "$seconds_epoch" '.[] |= . + {"Trigger": $trigger, "Create Seconds Epoch": ($epoch | tonumber) }' $json_file > $tmp_json_file
mv $tmp_json_file $json_file
echo "[TAKE-PHOTO-SCRIPT] Formatting JSON data" >> $general_logfile; 
# Formats the json layout to project requirements
jq '[.[] | .["File Name"] = .SourceFile | .["Create Date"] = .FileAccessDate | .["Subject Distance"] = (.SubjectDistance | rtrimstr(" m") | tonumber) | .["Exposure Time"] = .ExposureTime | del(.SourceFile, .ExposureTime, .FileAccessDate)] | map({ "File Name": .["File Name"], "Create Date": .["Create Date"], "Create Seconds Epoch": .["Create Seconds Epoch"], "Trigger": .Trigger, "Subject Distance": .["Subject Distance"], "Exposure Time": .["Exposure Time"], "ISO": .ISO })' $json_file > $tmp_json_file
mv $tmp_json_file $json_file

# Removes the [], because they were not present in the json layout on project requirements
jq '.[0]' $json_file > $tmp_json_file
mv $tmp_json_file $json_file
echo "[TAKE-PHOTO-SCRIPT] Saving JSON" >> $general_logfile; 
#-------------------------------GENERATING JSON FILE PART-----------------------------------

cd .. # Moves out of the today's directory folder
cd .. # Moves out of images folder

#-------------------------------GENERATING LOG.TXT FILE PART-----------------------------------
echo "[TAKE-PHOTO-SCRIPT] Adding Image to Transfer Logbook" >> $general_logfile; 
templog_file="imagelog_camera1.txt"
log_file="imagelog_camera1all.txt" 

# Check if temp log file exists
if [ ! -f "$templog_file" ]; then
    touch "$templog_file" # Make log file
fi

# Check if log file exists
if [ ! -f "$log_file" ]; then
    touch "$log_file" # Make log file
fi

echo "$current_date/$timestamp" >> $templog_file # Insert name of image to log file

echo "$current_date/$timestamp" >> $log_file # Insert name of image to log file

#-------------------------------GENERATING LOG.TXT FILE PART-----------------------------------