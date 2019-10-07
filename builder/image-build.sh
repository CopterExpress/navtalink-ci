#! /usr/bin/env bash

#
# Script for build the image. Used builder script of the target repo
# For build: docker run --privileged -it --rm -v /dev:/dev -v $(pwd):/builder/repo smirart/builder
#
# Copyright (C) 2019 Copter Express Technologies
#
# Author: Artem Smirnov <urpylka@gmail.com>
# Author: Andrey Dvornikov <dvornikov-aa@yandex.ru>
#

set -e # Exit immidiately on non-zero result

SOURCE_IMAGE="http://director.downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2019-07-12/2019-07-10-raspbian-buster-lite.zip"

export DEBIAN_FRONTEND=${DEBIAN_FRONTEND:='noninteractive'}
export LANG=${LANG:='C.UTF-8'}
export LC_ALL=${LC_ALL:='C.UTF-8'}

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

BUILDER_DIR="/builder"
REPO_DIR="${BUILDER_DIR}/repo"
SCRIPTS_DIR="${REPO_DIR}/builder"
IMAGES_DIR="${REPO_DIR}/images"
LIB_DIR="${REPO_DIR}/lib"

[[ ! -d ${SCRIPTS_DIR} ]] && (echo_stamp "Directory ${SCRIPTS_DIR} doesn't exist" "ERROR"; exit 1)
[[ ! -d ${IMAGES_DIR} ]] && mkdir ${IMAGES_DIR} && echo_stamp "Directory ${IMAGES_DIR} was created successful" "SUCCESS"

if [[ -z ${TRAVIS_TAG} ]]; then IMAGE_VERSION="$(cd ${REPO_DIR}; git log --format=%h -1)"; else IMAGE_VERSION="${TRAVIS_TAG}"; fi
# IMAGE_VERSION="${TRAVIS_TAG:=$(cd ${REPO_DIR}; git log --format=%h -1)}"
REPO_URL="$(cd ${REPO_DIR}; git remote --verbose | grep origin | grep fetch | cut -f2 | cut -d' ' -f1 | sed 's/git@github\.com\:/https\:\/\/github.com\//')"
REPO_NAME="navtalink-ci"
IMAGE_NAME="navtalink_${IMAGE_VERSION}.img"
IMAGE_PATH="${IMAGES_DIR}/${IMAGE_NAME}"

get_image() {
  # TEMPLATE: get_image <IMAGE_PATH> <RPI_DONWLOAD_URL>
  local BUILD_DIR=$(dirname $1)
  local RPI_ZIP_NAME=$(basename $2)
  local RPI_IMAGE_NAME=$(echo ${RPI_ZIP_NAME} | sed 's/zip/img/')

  if [ ! -e "${BUILD_DIR}/${RPI_ZIP_NAME}" ]; then
    echo_stamp "Downloading original Linux distribution"
    wget --progress=dot:giga -O ${BUILD_DIR}/${RPI_ZIP_NAME} $2
    echo_stamp "Downloading complete" "SUCCESS" \
  else echo_stamp "Linux distribution already donwloaded"; fi

  echo_stamp "Unzipping Linux distribution image" \
  && unzip -p ${BUILD_DIR}/${RPI_ZIP_NAME} ${RPI_IMAGE_NAME} > $1 \
  && echo_stamp "Unzipping complete" "SUCCESS" \
  || (echo_stamp "Unzipping was failed!" "ERROR"; exit 1)
}

get_image ${IMAGE_PATH} ${SOURCE_IMAGE}

# Make free space
${BUILDER_DIR}/image-resize.sh ${IMAGE_PATH} max '7G'

# Temporary disable ld.so
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} exec ${SCRIPTS_DIR}'/image-ld.sh' disable

# Copy cloned repository to the image
# Include dotfiles in globs (asterisks)
shopt -s dotglob

${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/init_rpi.sh' '/root/'
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/hardware_setup.sh' '/root/'
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} exec ${SCRIPTS_DIR}'/image-init.sh' ${IMAGE_VERSION} ${SOURCE_IMAGE}

# Copy libcyaml repository contents to the image
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${LIB_DIR}'/libcyaml' '/home/pi/libcyaml'
# Copy yaml-cpp repository contents to the image
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${LIB_DIR}'/yaml-cpp' '/home/pi/yaml-cpp'
# Copy spdlog repository contents to the image
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${LIB_DIR}'/spdlog' '/home/pi/spdlog'
# Copy cxxopts repository contents to the image
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${LIB_DIR}'/cxxopts' '/home/pi/cxxopts'
# Copy rtl8812au repository contents to the image
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${LIB_DIR}'/rtl8812au' '/home/pi/rtl8812au'
# Copy libseek-thermal repository contents to the image
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${LIB_DIR}'/libseek-thermal' '/home/pi/libseek-thermal'
# Copy raspicam repository contents to the image
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${LIB_DIR}'/raspicam' '/home/pi/raspicam'
# Copy mavlink-fast-switch repository contents to the image
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${LIB_DIR}'/mavlink-fast-switch' '/home/pi/mavlink-fast-switch'
# Copy mavlink-serial-bridge repository contents to the image
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${LIB_DIR}'/mavlink-serial-bridge' '/home/pi/mavlink-serial-bridge'
# Copy duocam-mavlink repository contents to the image
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${LIB_DIR}'/duocam-mavlink' '/home/pi/duocam-mavlink'
# Copy duocam-camera repository contents to the image
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${LIB_DIR}'/duocam-camera' '/home/pi/duocam-camera'
# Copy wifibroadcast repository contents to the image
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${LIB_DIR}'/wifibroadcast' '/home/pi/wifibroadcast'
# Add rename script
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/navtalink_rename' '/usr/local/bin/navtalink_rename'
# Add set role script
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/navtalink_set_role' '/usr/local/bin/navtalink_set_role'
# Add update adapter script
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/navtalink_update_adapter' '/usr/local/bin/navtalink_update_adapter'
# Add video stream script
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/navtalink_video' '/usr/local/bin/navtalink_video'
# Add video stream environment file
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/navtalink-video.env' '/lib/systemd/system/navtalink-video.env'
# Add video stream service file
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/navtalink-video.service' '/lib/systemd/system/navtalink-video.service'
# software install
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} exec ${SCRIPTS_DIR}'/image-software.sh'
# network setup
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} exec ${SCRIPTS_DIR}'/image-network.sh'

# If RPi then use a one thread to build a ROS package on RPi, else use all
[[ $(arch) == 'armv7l' ]] && NUMBER_THREADS=1 || NUMBER_THREADS=$(nproc --all)
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} exec ${SCRIPTS_DIR}'/image-validate.sh'
# Add options v4l2loopback
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/v4l2loopback.conf' '/etc/modprobe.d/v4l2loopback.conf'
# Update config for usbmode
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/usbmount.conf' '/etc/usbmount/usbmount.conf'
# Copy config for mavlink-serial-bridge
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/mavlink-serial-bridge.yaml' '/etc/mavlink-serial-bridge/drone.yaml'
# Copy config for mavlink-fast-switch
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/mavlink-fast-switch.yaml' '/etc/mavlink-fast-switch/duocam-drone.yaml'
# Copy config for wifibroadcast
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/wifibroadcast.cfg.drone' '/home/pi/navtalink/wifibroadcast.cfg.drone'
${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/wifibroadcast.cfg.gs' '/home/pi/navtalink/wifibroadcast.cfg.gs'

${BUILDER_DIR}/image-resize.sh ${IMAGE_PATH}
