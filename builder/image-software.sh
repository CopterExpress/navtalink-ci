#! /usr/bin/env bash

#
# Script for install software to the image.
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
  TEXT="\e[1m${TEXT}\e[0m" # BOLD

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

# https://gist.github.com/letmaik/caa0f6cc4375cbfcc1ff26bd4530c2a3
# https://github.com/travis-ci/travis-build/blob/master/lib/travis/build/templates/header.sh
my_travis_retry() {
  local result=0
  local count=1
  while [ $count -le 3 ]; do
    [ $result -ne 0 ] && {
      echo -e "\n${ANSI_RED}The command \"$@\" failed. Retrying, $count of 3.${ANSI_RESET}\n" >&2
    }
    # ! { } ignores set -e, see https://stackoverflow.com/a/4073372
    ! { "$@"; result=$?; }
    [ $result -eq 0 ] && break
    count=$(($count + 1))
    sleep 1
  done

  [ $count -gt 3 ] && {
    echo -e "\n${ANSI_RED}The command \"$@\" failed 3 times.${ANSI_RESET}\n" >&2
  }

  return $result
}

echo_stamp "Update apt"
apt-get update
#&& apt upgrade -y

echo_stamp "Upgrade kernel"
apt-get install -y --only-upgrade raspberrypi-kernel raspberrypi-bootloader \
|| (echo_stamp "Failed to upgrade kernel!" "ERROR"; exit 1)

echo_stamp "Software installing"
apt-get install --no-install-recommends -y \
unzip \
zip \
screen \
byobu  \
lsof \
git \
dnsmasq \
tmux \
vim \
cmake \
ltrace \
build-essential \
pigpio python-pigpio \
i2c-tools \
ntpdate \
python-dev \
libxml2-dev \
libxslt-dev \
python-future \
python-lxml \
mc \
libboost-system-dev \
libboost-program-options-dev \
libboost-thread-dev \
libreadline-dev \
socat \
dnsmasq \
autoconf \
automake \
libtool \
python3-future \
libpcap-dev \
wiringpi \
libsodium-dev \
libopencv-dev \
libusb-1.0-0-dev \
libsystemd-dev \
libexiv2-dev \
libv4l-dev \
v4l2loopback-dkms \
gstreamer1.0-tools \
gstreamer1.0-plugins-good \
gstreamer1.0-plugins-bad \
gstreamer1.0-omx \
ntfs-3g \
raspberrypi-kernel-headers \
virtualenv \
fakeroot \
debhelper \
python-twisted \
python-pyroute2 \
python-future \
python-configparser \
python-all \
libyaml-dev \
&& echo_stamp "Everything was installed!" "SUCCESS" \
|| (echo_stamp "Some packages wasn't installed!" "ERROR"; exit 1)

# echo_stamp "Updating kernel to fix camera bug"
# apt-get install --no-install-recommends -y raspberrypi-kernel=1.20190401-1

# Deny byobu to check available updates
sed -i "s/updates_available//" /usr/share/byobu/status/status
# sed -i "s/updates_available//" /home/pi/.byobu/status

echo_stamp "Installing pip"
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py
rm get-pip.py
#my_travis_retry pip install --upgrade pip
#my_travis_retry pip3 install --upgrade pip

echo_stamp "Make sure both pip is installed"
pip --version

echo_stamp "Install usbmount"
cd /home/pi \
&& wget https://github.com/nicokaiser/usbmount/releases/download/0.0.24/usbmount_0.0.24_all.deb \
&& apt install --no-install-recommends -y ./usbmount_0.0.24_all.deb \
&& rm ./usbmount_0.0.24_all.deb \
|| (echo_stamp "Failed to install usbmount pymavlink!" "ERROR"; exit 1)

echo_stamp "Build libcyaml"
cd /home/pi/libcyaml \
&& git status \
&& make -j4 \
&& make install \
&& cd .. \
&& rm -r libcyaml \
|| (echo_stamp "Failed to build libcyaml!" "ERROR"; exit 1)

echo_stamp "Build spdlog"
cd /home/pi/spdlog \
&& git status \
&& mkdir build \
&& cd build \
&& cmake -DSPDLOG_BUILD_BENCH=OFF -DSPDLOG_BUILD_TESTS=OFF .. \
&& make -j4 \
&& make install \
&& cd ../.. \
&& rm -r spdlog \
|| (echo_stamp "Failed to build spdlog!" "ERROR"; exit 1)

echo_stamp "Build yaml-cpp"
cd /home/pi/yaml-cpp \
&& git status \
&& mkdir build \
&& cd build \
&& cmake -DYAML_CPP_BUILD_TESTS=OFF .. \
&& make -j4 \
&& make install \
&& cd ../.. \
&& rm -r yaml-cpp \
|| (echo_stamp "Failed to build yaml-cpp!" "ERROR"; exit 1)

echo_stamp "Build cxxopts"
cd /home/pi/cxxopts \
&& git status \
&& mkdir build \
&& cd build \
&& cmake -DCXXOPTS_BUILD_EXAMPLES=OFF -DCXXOPTS_BUILD_TESTS=OFF .. \
&& make -j4 \
&& make install \
&& cd ../.. \
&& rm -r cxxopts \
|| (echo_stamp "Failed to build cxxopts!" "ERROR"; exit 1)

echo_stamp "Build libseek-thermal"
cd /home/pi/libseek-thermal \
&& git status \
&& mkdir build \
&& cd build \
&& cmake .. \
&& make -j4 \
&& make install \
&& cd ../.. \
&& rm -r libseek-thermal \
|| (echo_stamp "Failed to build libseek-thermal!" "ERROR"; exit 1)

echo_stamp "Build raspicam"
cd /home/pi/raspicam \
&& git status \
&& mkdir build \
&& cd build \
&& cmake .. \
&& make -j4 \
&& make install \
&& cd ../.. \
&& rm -r raspicam \
|| (echo_stamp "Failed to build raspicam!" "ERROR"; exit 1)

echo_stamp "Build mavlink-fast-switch"
cd /home/pi/mavlink-fast-switch \
&& git status \
&& mkdir build \
&& cd build \
&& cmake .. \
&& make -j4 \
&& make install \
|| (echo_stamp "Failed to build mavlink-fast-switch!" "ERROR"; exit 1)

echo_stamp "Build mavlink-serial-bridge"
cd /home/pi/mavlink-serial-bridge \
&& git status \
&& mkdir build \
&& cd build \
&& cmake .. \
&& make -j4 \
&& make install \
|| (echo_stamp "Failed to build mavlink-serial-bridge!" "ERROR"; exit 1)

echo_stamp "Build duocam-camera"
cd /home/pi/duocam-camera \
&& git status \
&& mkdir build \
&& cd build \
&& cmake .. \
&& make -j4 \
&& make install \
|| (echo_stamp "Failed to build duocam-camera!" "ERROR"; exit 1)

echo_stamp "Build duocam-mavlink"
cd /home/pi/duocam-mavlink \
&& git status \
&& mkdir build \
&& cd build \
&& cmake -DNO_EXAMPLES=ON .. \
&& make -j4 \
&& make install \
|| (echo_stamp "Failed to build duocam-mavlink!" "ERROR"; exit 1)

echo_stamp "Build wifibroadcast"
cd /home/pi/wifibroadcast \
&& git status \
&& make -j4 all_bin \
&& python setup.py install \
&& cd .. \
&& rm -r wifibroadcast \
|| (echo_stamp "Failed to build wifibroadcast!" "ERROR"; exit 1)

# ./dkms-install.sh fails in chroot environment. We have to perform build and install
# steps manually with kernels installed in the target system.
echo_stamp "Build rtl8812au"
cd /home/pi/rtl8812au && \
git status

DRV_DIR=$(grep -Po "DRV_DIR=\K([a-z0-9]+)" ./dkms-install.sh) \
|| (echo_stamp "Failed to extract DRV_DIR!" "ERROR"; exit 1)
echo "DRV_DIR=$DRV_DIR"

DRV_NAME=$(grep -Po "DRV_NAME=\K([a-z0-9]+)" ./dkms-install.sh) \
|| (echo_stamp "Failed to extract DRV_NAME!" "ERROR"; exit 1)
echo "DRV_NAME=$DRV_NAME"

DRV_VERSION=$(grep -Po "DRV_VERSION=\K([0-9.]+)" ./dkms-install.sh) \
|| (echo_stamp "Failed to extract DRV_VERSION!" "ERROR"; exit 1)
echo "DRV_VERSION=$DRV_VERSION"

cp -r $(pwd) /usr/src/${DRV_NAME}-${DRV_VERSION} \
|| (echo_stamp "Failed to create a symlink for the rtl8812au DKMS module!" "ERROR"; exit 1)

dkms add -m ${DRV_NAME} -v ${DRV_VERSION} \
|| (echo_stamp "Failed to add the rtl8812au DKMS module!" "ERROR"; exit 1)

linux_headers=($(ls -1a /usr/src | grep -Po "linux-headers-\K([a-z0-9.=+-]+)")) \
|| (echo_stamp "Failed to retrieve target system kernels!" "ERROR"; exit 1)
for i in "${linux_headers[@]}"
do
  dkms build -m ${DRV_NAME} -v ${DRV_VERSION} -k "$i" \
  || (echo_stamp "Failed to build rtl8812au for kernel $i!" "ERROR"; exit 1)
  dkms install -m ${DRV_NAME} -v ${DRV_VERSION} -k "$i" \
  || (echo_stamp "Failed to install rtl8812au for kernel $i!" "ERROR"; exit 1)
done

cat << EOF >> /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

cd .. \
&& rm -r rtl8812au \
|| (echo_stamp "Failed to remove rtl8812au sources!" "ERROR"; exit 1)

echo_stamp "Reconfigure shared objects"
ldconfig \
|| (echo_stamp "Failed to reconfigure shared objects!" "ERROR"; exit 1)

echo_stamp "Register kernel modules"
echo "v4l2loopback" >> /etc/modules \
&& echo "88XXau" >> /etc/modules \
|| (echo_stamp "Failed to register kernel modules!" "ERROR"; exit 1)

echo_stamp "Add .vimrc"
cat << EOF > /home/pi/.vimrc
set mouse-=a
syntax on
autocmd BufNewFile,BufRead *.launch set syntax=xml
EOF

echo_stamp "Change default keyboard layout to US"
sed -i 's/XKBLAYOUT="gb"/XKBLAYOUT="us"/g' /etc/default/keyboard

echo_stamp "Configure services"
systemctl enable wifibroadcast \
|| (echo_stamp "Failed to configure services!" "ERROR"; exit 1)

echo_stamp "End of software installation"
