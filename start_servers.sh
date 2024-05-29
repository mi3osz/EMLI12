#!/bin/bash
general_logfile="/home/phub/project/main_log"

echo "[**Services-Startup**] Started Main Script" >> $general_logfile;
#This script will start the other background scripts. Running this script starts the code
/home/phub/project/external_trigger.sh &
echo "[**Services-Startup**] External Trigger Started with PID: $!" >> $general_logfile;
/home/phub/project/wiper_control.sh &
echo "[**Services-Startup**] Wiper Control Started with PID: $!" >> $general_logfile;
/home/phub/project/pico_communication.sh &
echo "[**Services-Startup**] Pico Communication Started with PID: $!" >> $general_logfile;
/home/phub/project/motion_detection.sh &
echo "[**Services-Startup**] Motion Detection Started with PID: $!" >> $general_logfile;