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

export BUILD_PREFIX=~/turnip_drivers
if [ -e $BUILD_PREFIX ]; then
   echo -e "${RED}${BOLD}${BUILD_PREFIX} already exists${NC}${NORMAL}"
else
   mkdir ${BUILD_PREFIX}
fi

cd ${BUILD_PREFIX}

cp /usr/include/libdrm/drm.h /usr/include/libdrm/drm_mode.h /usr/include/
export MESA_PREFIX=${BUILD_PREFIX}/mesa-review-tu-ray-query

if [ -e $MESA_PREFIX ]; then
   echo -e "${RED}${BOLD}${MESA_PREFIX} already exists${NC}${NORMAL}"
else
   echo -e "${CYAN}${BOLD}Cloning turnip drivers${NC}${NORMAL}"
   wget --continue --directory-prefix ${BUILD_PREFIX} https://gitlab.freedesktop.org/cwabbott0/mesa/-/archive/review/tu-ray-query/mesa-review-tu-ray-query.tar.gz
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

wget https://raw.githubusercontent.com/nydal91/turnip_termux/main/159bdeb49f8b32796737bad7c6ba1041dc9f6483.patch
git apply -v 159bdeb49f8b32796737bad7c6ba1041dc9f6483.patch
##rm ${MESA_PREFIX}/src/vulkan/wsi/wsi_common_x11.c
##cp ${BUILD_PREFIX}/wsi_common_x11.c ${MESA_PREFIX}/src/vulkan/wsi/

echo -e "${GREEN}${BOLD}Starting to compile${NC}${NORMAL}"
meson setup build64/ --prefix /usr/local --libdir lib/aarch64-linux-gnu/ -D platforms=x11,wayland -D gallium-drivers=freedreno -D vulkan-drivers=freedreno -D freedreno-kmds=msm,kgsl -D dri3=enabled -D buildtype=release -D glx=disabled -D egl=disabled -D gles1=disabled -D gles2=disabled -D gallium-xa=disabled -D opengl=false -D shared-glapi=false -D b_lto=true -D b_ndebug=true -D cpp_rtti=false -D gbm=disabled -D llvm=disabled -D shared-llvm=disabled -D xmlconfig=disabled
meson compile -C build64/
meson install -C build64/ --destdir ${MESA_64}
