#!/bin/bash

# Preparing

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
NC="\033[0m"
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

echo "
deb http://ports.ubuntu.com/ubuntu-ports jammy main restricted universe multiverse
deb-src http://ports.ubuntu.com/ubuntu-ports jammy main restricted universe multiverse

deb http://ports.ubuntu.com/ubuntu-ports jammy-updates main restricted universe multiverse
deb-src http://ports.ubuntu.com/ubuntu-ports jammy-updates main restricted universe multiverse

deb http://ports.ubuntu.com/ubuntu-ports jammy-backports main restricted universe multiverse
deb-src http://ports.ubuntu.com/ubuntu-ports jammy-backports main restricted universe multiverse

deb http://ports.ubuntu.com/ubuntu-ports jammy-security main restricted universe multiverse
deb-src http://ports.ubuntu.com/ubuntu-ports jammy-security main restricted universe multiverse
" > /etc/apt/sources.list

dpkg --add-architecture armhf
apt update
apt upgrade
apt build-dep mesa 
apt install make cmake git wget vulkan-tools mesa-utils g++-arm-linux-gnueabihf g++-aarch64-linux-gnu
apt install zlib1g-dev:armhf libexpat1-dev:armhf libdrm-dev:armhf libx11-dev:armhf libx11-xcb-dev:armhf libxext-dev:armhf libxdamage-dev:armhf libxcb-glx0-dev:armhf libxcb-dri2-0-dev:armhf libxcb-dri3-dev:armhf libxcb-shm0-dev:armhf libxcb-present-dev:armhf libxshmfence-dev:armhf libxxf86vm-dev:armhf libxrandr-dev:armhf libwayland-dev:armhf wayland-protocols:armhf libwayland-egl-backend-dev:armhf 
apt install zlib1g-dev:arm64 libexpat1-dev:arm64 libdrm-dev:arm64 libx11-dev:arm64 libx11-xcb-dev:arm64 libxext-dev:arm64 libxdamage-dev:arm64 libxcb-glx0-dev:arm64 libxcb-dri2-0-dev:arm64 libxcb-dri3-dev:arm64 libxcb-shm0-dev:arm64 libxcb-present-dev:arm64 libxshmfence-dev:arm64 libxxf86vm-dev:arm64 libxrandr-dev:arm64 libwayland-dev:arm64 wayland-protocols:arm64 libwayland-egl-backend-dev:arm64  
cp /usr/include/libdrm/drm.h /usr/include/libdrm/drm_mode.h /usr/include/

export BUILD_PREFIX=~/turnip_drivers
if [ -e $BUILD_PREFIX ]; then
   echo -e "${RED}${BOLD}${BUILD_PREFIX} already exists${NC}${NORMAL}"
else
   mkdir ${BUILD_PREFIX}
fi

cd ${BUILD_PREFIX}

cp /usr/include/libdrm/drm.h /usr/include/libdrm/drm_mode.h /usr/include/
export MESA_PREFIX=${BUILD_PREFIX}/mesa-main

if [ -e $MESA_PREFIX ]; then
   echo -e "${RED}${BOLD}${MESA_PREFIX} already exists${NC}${NORMAL}"
else
   echo -e "${CYAN}${BOLD}Cloning turnip drivers${NC}${NORMAL}"
   wget --continue --directory-prefix ${BUILD_PREFIX} https://gitlab.freedesktop.org/mesa/mesa/-/archive/main/mesa-main.tar.gz
fi

echo -e "${CYAN}${BOLD}Extracting the drivers${NC}${NORMAL}"
tar -xf ${BUILD_PREFIX}/*.tar.gz --directory ${BUILD_PREFIX}
MESA_VER=$(cat ${MESA_PREFIX}/VERSION)
DATE=$(date +"%F" | sed 's/-//g')
MESA_64=${BUILD_PREFIX}/mesa-vulkan-kgsl_${MESA_VER}-${DATE}_arm64
echo "\

[binaries]
c = 'arm-linux-gnueabihf-gcc'
cpp = 'arm-linux-gnueabihf-g++'
ar = 'arm-linux-gnueabihf-ar'
strip = 'arm-linux-gnueabihf-strip'
pkgconfig = 'arm-linux-gnueabihf-pkg-config'

[host_machine]
system = 'linux'
cpu_family = 'arm'
cpu = 'aarch64'
endian = 'little'
" > ${MESA_PREFIX}/arm.txt

echo -e "${CYAN}${BOLD}Cloning DRI3 patch${NC}${NORMAL}"
##wget ${BUILD_PREFIX} https://github.com/xDoge26/proot-setup/files/12564533/dri.zip
##unzip dri.zip
##echo -e "${CYAN}${BOLD}Extracting the patch${NC}${NORMAL}"
##cp ${BUILD_PREFIX}/wsi-termux-x11-v3.patch ${MESA_PREFIX}
cd ${MESA_PREFIX}
wget https://github.com/alexvorxx/Zink-Mesa-Xlib/releases/download/v0.0.7beta/04-wsi-termux-x11-only-kgsl_fixed.patch
echo -e "${GREEN}${BOLD}Applying the patch${NC}${NORMAL}"
git apply -v 04-wsi-termux-x11-only-kgsl_fixed.patch

##rm ${MESA_PREFIX}/src/vulkan/wsi/wsi_common_x11.c
##cp ${BUILD_PREFIX}/wsi_common_x11.c ${MESA_PREFIX}/src/vulkan/wsi/

echo -e "${GREEN}${BOLD}Starting to compile${NC}${NORMAL}"
meson setup build64/ --prefix /usr --libdir lib/aarch64-linux-gnu/ -D platforms=x11,wayland -D gallium-drivers=freedreno -D vulkan-drivers=freedreno -D freedreno-kmds=msm,kgsl -D dri3=enabled -D buildtype=release -D glx=disabled -D egl=disabled -D gles1=disabled -D gles2=disabled -D gallium-xa=disabled -D opengl=false -D shared-glapi=false -D b_lto=true -D b_ndebug=true -D cpp_rtti=false -D gbm=disabled -D llvm=disabled -D shared-llvm=disabled -D xmlconfig=disabled
meson compile -C build64/
meson install -C build64/ --destdir ${MESA_64}
