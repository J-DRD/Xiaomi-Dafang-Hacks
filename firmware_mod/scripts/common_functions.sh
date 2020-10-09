#!/bin/sh

# This file is supposed to bundle some frequently used functions
# so they can be easily improved in one place and be reused all over the place

include () {
    [[ -f "$1" ]] && source "$1"
}

# Try to detect hardware model
detect_model(){
  if [ -f /driver/8189es.ko ]; then
    # Its a DaFang
    echo "Xiaomi Dafang"
  elif [ -f /driver/8189fs.ko ]; then
    # Its a XiaoFang T20
    echo "Xiaomi Xiaofang 1S"
  else
    # Its a NEOS SmartCam / Wyzecam V2
    echo "NEOS SmartCam / Wyzecam V2"
  fi
}
# Initialize  gpio pin
init_gpio(){
  GPIOPIN=$1
  echo "$GPIOPIN" > /sys/class/gpio/export
  case $2 in
    in)
      echo "in" > "/sys/class/gpio/gpio$GPIOPIN/direction"
      ;;
    *)
      echo "out" > "/sys/class/gpio/gpio$GPIOPIN/direction"
      ;;
  esac
  echo 0 > "/sys/class/gpio/gpio$GPIOPIN/active_low"
}

# Read a value from a gpio pin
getgpio(){
  GPIOPIN=$1
  cat /sys/class/gpio/gpio"$GPIOPIN"/value
}

# Write a value to gpio pin
setgpio() {
  GPIOPIN=$1
  echo "$2" > "/sys/class/gpio/gpio$GPIOPIN/value"
}

# Get value for a key in a config_file
# ignore commented lines
get_config(){
  cfg_path=$1
  cfg_key=$2
  grep -v '^[[:space:]]*#' "$1"  | grep "$2" | cut -d "=" -f2
}

# Replace the old value of a config_key at the cfg_path with new_value
# Don't rewrite commented lines
rewrite_config(){
  cfg_path=$1
  cfg_key=$2
  new_value=$3

  # Check if the value exists (without comment), if not add it to the file
  $(grep -v '^[[:space:]]*#' "$1"  | grep -q "$2")
  ret="$?"
  if [ "$ret" == "1" ] ; then
      echo "$2=$3" >> $1
  else
        sed -i -e "/\\s*#.*/!{/""$cfg_key""=/ s/=.*/=""$new_value""/}" "$cfg_path"
  fi
}

# Control the blue led
blue_led(){
  case "$1" in
  on)
    setgpio 39 0
    ;;
  off)
    setgpio 39 1
    ;;
  status)
    status=$(getgpio 39)
    case $status in
      0)
        echo "ON"
        ;;
      1)
        echo "OFF"
      ;;
    esac
  esac
}

# Control the yellow led
yellow_led(){
  case "$1" in
  on)
    setgpio 38 0
    ;;
  off)
    setgpio 38 1
    ;;
  status)
    status=$(getgpio 38)
    case $status in
      0)
        echo "ON"
        ;;
      1)
        echo "OFF"
      ;;
    esac
  esac
}

# Control the infrared led
ir_led(){
  case "$1" in
  on)
    setgpio 49 0
    ;;
  off)
    setgpio 49 1
    ;;
  status)
    status=$(getgpio 49)
    case $status in
      0)
        echo "ON"
        ;;
      1)
        echo "OFF"
      ;;
    esac
  esac
}

# Control the infrared filter
ir_cut(){
  case "$1" in
  on)
    setgpio 25 0
    setgpio 26 1
    sleep 1
    setgpio 26 0
    echo "1" > /var/run/ircut
    ;;
  off)
    setgpio 26 0
    setgpio 25 1
    sleep 1
    setgpio 25 0
    echo "0" > /var/run/ircut
    ;;
  status)
    status=$(cat /var/run/ircut)
    case $status in
      1)
        echo "ON"
        ;;
      0)
        echo "OFF"
      ;;
    esac
  esac
}

# Read the hw light sensor (hw in mqtt.conf)
ldr(){
  case "$1" in
  status)
    brightness=$(dd if=/dev/jz_adc_aux_0 count=20 2> /dev/null |  sed -e 's/[^\.]//g' | wc -m)
    echo "$brightness"
  esac
}

# Read the virtual light sensor (virtual in mqtt.conf)
exposure(){
  case "$1" in
  status)
    isp_exposure=$(grep 'ISP exposure log2 id:' /proc/jz/isp/isp_info  | sed 's/^.*: //')
    echo "$isp_exposure"
  esac
}

# Control the http server
http_server(){
  case "$1" in
  on)
    /system/sdcard/bin/lighttpd -f /system/sdcard/config/lighttpd.conf
    ;;
  off)
    killall lighttpd.bin
    ;;
  restart)
    killall lighttpd.bin
    /system/sdcard/bin/lighttpd -f /system/sdcard/config/lighttpd.conf
    ;;
  status)
    if pgrep lighttpd.bin &> /dev/null
      then
        echo "ON"
    else
        echo "OFF"
    fi
    ;;
  esac
}

# Set a new http password
http_password(){
  user="root" # by default root until we have proper user management
  realm="all" # realm is defined in the lightppd.conf
  pass=$1
  hash=$(echo -n "$user:$realm:$pass" | md5sum | cut -b -32)
  echo "$user:$realm:$hash" > /system/sdcard/config/lighttpd.user
}

# Control the RTSP h264 server
rtsp_h264_server(){
  case "$1" in
  on)
    /system/sdcard/controlscripts/rtsp-h264 start
    ;;
  off)
    /system/sdcard/controlscripts/rtsp-h264 stop
    ;;
  status)
    if /system/sdcard/controlscripts/rtsp-h264 status | grep -q "PID"
      then
        echo "ON"
    else
        echo "OFF"
    fi
    ;;
  esac
}

# Control the RTSP mjpeg server
rtsp_mjpeg_server(){
  case "$1" in
  on)
    /system/sdcard/controlscripts/rtsp-mjpeg start
    ;;
  off)
    /system/sdcard/controlscripts/rtsp-mjpeg stop
    ;;
  status)
    if /system/sdcard/controlscripts/rtsp-mjpeg status | grep -q "PID"
    then
        echo "ON"
    else
        echo "OFF"
    fi
    ;;
  esac
}

# Control the video recorder
recording(){
  case "$1" in
  on)
    /system/sdcard/controlscripts/recording start
    ;;
  off)
    /system/sdcard/controlscripts/recording stop
    ;;
  status)
    if /system/sdcard/controlscripts/recording status | grep -q "PID"
    then
        echo "ON"
    else
        echo "OFF"
    fi
    ;;
  esac
}

# Control the ftp server
ftp_server(){
  case "$1" in
  on)
    /system/sdcard/controlscripts/ftp_server start
    ;;
  off)
    /system/sdcard/controlscripts/ftp_server stop
    ;;
  status)
    if /system/sdcard/controlscripts/ftp_server status | grep -q "PID"
    then
        echo "ON"
    else
        echo "OFF"
    fi
    ;;
  esac
}

# Control the timelapse
timelapse(){
  case "$1" in
  on)
    /system/sdcard/controlscripts/timelapse start
    ;;
  off)
    /system/sdcard/controlscripts/timelapse stop
    ;;
  status)
    if /system/sdcard/controlscripts/timelapse status | grep -q "PID"
    then
        echo "ON"
    else
        echo "OFF"
    fi
    ;;
  esac
}

# Control the motion detection function
motion_detection(){
  case "$1" in
  on)
    /system/sdcard/bin/setconf -k m -v $(get_config /system/sdcard/config/motion.conf motion_sensitivity)
    rewrite_config /system/sdcard/config/motion.conf motion_detection "on"
    ;;
  off)
    /system/sdcard/bin/setconf -k m -v -1
    rewrite_config /system/sdcard/config/motion.conf motion_detection "off"
    ;;
  status)
    status=$(/system/sdcard/bin/setconf -g m 2>/dev/null)
    case $status in
      -1)
        echo "OFF"
        ;;
      *)
        echo "ON"
        ;;
    esac
  esac
}

# Control the motion detection led function
motion_led(){
  case "$1" in
  on)
    rewrite_config /system/sdcard/config/motion.conf motion_trigger_led "true"
    ;;
  off)
    rewrite_config /system/sdcard/config/motion.conf motion_trigger_led "false"
    ;;
  status)
    status=$(grep '^[^#;]' /system/sdcard/config/motion.conf|grep 'motion_trigger_led'|cut -f2 -d \=)
    case $status in
      true)
        echo "ON"
        ;;
      false)
        echo "OFF"
        ;;
    esac
  esac
}

# Control the motion detection mail function
motion_send_mail(){
  case "$1" in
  on)
    rewrite_config /system/sdcard/config/motion.conf send_email "true"
    ;;
  off)
    rewrite_config /system/sdcard/config/motion.conf send_email "false"
    ;;
  status)
    status=$(grep '^[^#;]' /system/sdcard/config/motion.conf|grep 'send_email'|cut -f2 -d \=)
    case $status in
      false)
        echo "OFF"
        ;;
      true)
        echo "ON"
        ;;
    esac
  esac
}

# Control the motion detection Telegram function
motion_send_telegram(){
  case "$1" in
  on)
    rewrite_config /system/sdcard/config/motion.conf send_telegram "true"
    ;;
  off)
    rewrite_config /system/sdcard/config/motion.conf send_telegram "false"
    ;;
  status)
    status=$(grep '^[^#;]' /system/sdcard/config/motion.conf|grep 'send_telegram'|cut -f2 -d \=)
    case $status in
      true)
        echo "ON"
        ;;
      *)
        echo "OFF"
        ;;
    esac
  esac
}

# Control the motion detection snapshot function
motion_snapshot(){
  case "$1" in
  on)
    rewrite_config /system/sdcard/config/motion.conf save_snapshot "true"
    ;;
  off)
    rewrite_config /system/sdcard/config/motion.conf save_snapshot "false"
    ;;
  status)
    status=$(grep '^[^#;]' /system/sdcard/config/motion.conf|grep 'save_snapshot[^_]'|cut -f2 -d \=)
    case $status in
      false)
        echo "OFF"
        ;;
      true)
        echo "ON"
        ;;
    esac
  esac
}

# Control the motion detection video function
motion_video(){
  case "$1" in
  on)
    rewrite_config /system/sdcard/config/motion.conf save_video "true"
    ;;
  off)
    rewrite_config /system/sdcard/config/motion.conf save_video "false"
    ;;
  status)
    status=$(grep '^[^#;]' /system/sdcard/config/motion.conf|grep 'save_video[^_]'|cut -f2 -d \=)
    case $status in
      true)
        echo "ON"
        ;;
      false)
        echo "OFF"
        ;;
    esac
  esac
}

# Control the motion tracking function
motion_tracking(){
  case "$1" in
  on)
    /system/sdcard/bin/setconf -k t -v on
    ;;
  off)
    /system/sdcard/bin/setconf -k t -v off
    ;;
  status)
    status=$(/system/sdcard/bin/setconf -g t 2>/dev/null)
    case $status in
      true)
        echo "ON"
        ;;
      *)
        echo "OFF"
        ;;
    esac
  esac
}

# Control the motion detection publish MQTT-message function
motion_mqtt_publish(){
  case "$1" in
  on)
    rewrite_config /system/sdcard/config/motion.conf publish_mqtt_message "true"
    ;;
  off)
    rewrite_config /system/sdcard/config/motion.conf publish_mqtt_message "false"
    ;;
  status)
    status=$(grep '^[^#;]' /system/sdcard/config/motion.conf|grep 'publish_mqtt_message'|cut -f2 -d \=)
    case $status in
      true)
        echo "ON"
        ;;
      false)
        echo "OFF"
        ;;
    esac
  esac
}

# Control the motion detection publish snapshots in MQTT-message function
motion_mqtt_snapshot(){
  case "$1" in
  on)
    rewrite_config /system/sdcard/config/motion.conf publish_mqtt_snapshot "true"
    ;;
  off)
    rewrite_config /system/sdcard/config/motion.conf publish_mqtt_snapshot "false"
    ;;
  status)
    status=$(grep '^[^#;]' /system/sdcard/config/motion.conf|grep 'publish_mqtt_snapshot'|cut -f2 -d \=)
    case $status in
      true)
        echo "ON"
        ;;
      false)
        echo "OFF"
        ;;
    esac
  esac
}

# Control the motion detection publish video in MQTT-message function
motion_mqtt_video(){
  case "$1" in
  on)
    rewrite_config /system/sdcard/config/motion.conf publish_mqtt_video "true"
    ;;
  off)
    rewrite_config /system/sdcard/config/motion.conf publish_mqtt_video "false"
    ;;
  status)
    status=$(grep '^[^#;]' /system/sdcard/config/motion.conf|grep 'publish_mqtt_video'|cut -f2 -d \=)
    case $status in
      true)
        echo "ON"
        ;;
      false)
        echo "OFF"
        ;;
    esac
  esac
}

# Control the night mode
night_mode(){
  case "$1" in
  on)
    /system/sdcard/bin/setconf -k n -v 1
    . /system/sdcard/config/autonight.conf
    if [ -z "$ir_led_off" ] || [ $ir_led_off = false ]; then
        ir_led on
    else
        ir_led off
    fi
    ir_cut off
    ;;
  off)
    ir_led off
    ir_cut on
    /system/sdcard/bin/setconf -k n -v 0
    ;;
  status)
    status=$(/system/sdcard/bin/setconf -g n)
    case $status in
      0)
        echo "OFF"
        ;;
      1)
        echo "ON"
        ;;
    esac
  esac
}

# Control the auto night mode
auto_night_mode(){
  case "$1" in
    on)
      /system/sdcard/controlscripts/auto-night-detection start
      ;;
    off)
      /system/sdcard/controlscripts/auto-night-detection stop
      ;;
    status)
      if [ -f /run/auto-night-detection.pid ]; then
        echo "ON";
      else
        echo "OFF"
      fi
  esac
}

# Take a snapshot
snapshot(){
    filename="/tmp/snapshot.jpg"
    /system/sdcard/bin/getimage > "$filename" &
    sleep 1
}

# Set timezone from the timezone config file to system timezone
set_timezone(){
  timezone_name=$(cat /system/sdcard/config/timezone.conf)
  timezone=$(/system/sdcard/bin/busybox awk -F '\t' -v tzn="$timezone_name" '($1==tzn) {print $2}' /system/sdcard/www/timezones.tsv)
  if [ "$(cat /etc/TZ)" != "$timezone" ]; then
    echo "$timezone" > /etc/TZ
  fi
}

# Reboot the System
reboot_system() {
  /sbin/reboot
}

# Re-Mount the SD Card
remount_sdcard() {
  mount -o remount,rw /system/sdcard
}

# Check commit between VERSION file and github
check_commit() {
  if [ -s /system/sdcard/VERSION ]; then
    localcommit=$(/system/sdcard/bin/jq -r .commit /system/sdcard/VERSION)
    localbranch=$(/system/sdcard/bin/jq -r .branch /system/sdcard/VERSION)
    remotecommit=$(/system/sdcard/bin/curl -s https://api.github.com/repos/EliasKotlyar/Xiaomi-Dafang-Hacks/commits/${localbranch} | /system/sdcard/bin/jq -r '.sha[0:7]')
    if [ ${localcommit} = ${remotecommit} ]; then
     echo "${localcommit} ( No update available)"
    else
     commitbehind=$(/system/sdcard/bin/curl -s https://api.github.com/repos/EliasKotlyar/Xiaomi-Dafang-Hacks/compare/${remotecommit}...${localcommit} | /system/sdcard/bin/jq -r '.behind_by')
     echo "${localcommit} ( ${commitbehind} commits behind Github)"
    fi
  else
    echo "No version file"
  fi
}