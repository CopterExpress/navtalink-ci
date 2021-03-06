#! /usr/bin/env bash

#
# Script for network configure
#
# Copyright (C) 2019 Copter Express Technologies
#
# Author: Artem Smirnov <urpylka@gmail.com>
# Author: Andrey Dvornikov <dvornikov-aa@yandex.ru>
#

set -e # Exit immidiately on non-zero result

echo_stamp() {
  # TEMPLATE: echo_stamp <TEXT> <TYPE>
  # TYPE: SUCCESS, ERROR, INFO

  # More info there https://www.shellhacks.com/ru/bash-colors/

  TEXT="$(date '+[%Y-%m-%d %H:%M:%S]') $1"
  TEXT="\e[1m$TEXT\e[0m" # BOLD

  case "$2" in
    SUCCESS)
    TEXT="\e[32m${TEXT}\e[0m";; # GREEN
    ERROR)
    TEXT="\e[31m${TEXT}\e[0m";; # RED
    *)
    TEXT="\e[34m${TEXT}\e[0m";; # BLUE
  esac
  echo -e ${TEXT}
}

echo_stamp "#1 Write to /etc/wpa_supplicant/wpa_supplicant.conf"

# TODO: Use wpa_cli instead direct file edit
cat << EOF >> /etc/wpa_supplicant/wpa_supplicant.conf
network={
    ssid="NAVTALINK"
    psk="navtalinkwifi"
    mode=2
    proto=RSN
    key_mgmt=WPA-PSK
    pairwise=CCMP
    group=CCMP
    auth_alg=OPEN
}
EOF
mv /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

# WARNING: Internal WiFi adapter doesn't follow predictable interface naming rule and can change its number
echo_stamp "#2 Create symlinks to /etc/wpa_supplicant/wpa_supplicant-wlan0.conf"
ln -s /etc/wpa_supplicant/wpa_supplicant-wlan0.conf /etc/wpa_supplicant/wpa_supplicant-wlan1.conf \
&& ln -s /etc/wpa_supplicant/wpa_supplicant-wlan0.conf /etc/wpa_supplicant/wpa_supplicant-wlan2.conf \
&& ln -s /etc/wpa_supplicant/wpa_supplicant-wlan0.conf /etc/wpa_supplicant/wpa_supplicant-wlan3.conf \
|| (echo_stamp "Failed to create symlinks!" "ERROR"; exit 1)

echo_stamp "#3 Write STATIC to /etc/dhcpcd.conf"

cat << EOF >> /etc/dhcpcd.conf
interface wlan0
static ip_address=192.168.30.1/24
interface wlan1
static ip_address=192.168.30.1/24
interface wlan2
static ip_address=192.168.30.1/24
interface wlan3
static ip_address=192.168.30.1/24
EOF

echo_stamp "#4 Write dhcp-config to /etc/dnsmasq.conf"

cat << EOF >> /etc/dnsmasq.conf
interface=wlan0
interface=wlan1
interface=wlan2
interface=wlan3
address=/navtalink/192.168.30.1
dhcp-range=192.168.30.2,192.168.30.2,2m
no-hosts
filterwin2k
bogus-priv
domain-needed
quiet-dhcp6
EOF

echo_stamp "#5 End of network installation"
