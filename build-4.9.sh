#!/usr/bin/env bash
#
# Gets the source for Raspberry Pi Linux 4.14, patches it with I-Pipe
# and Xenomai, and builds the kernel.

readonly RED='\033[0;31m'
readonly NOCOLOR='\033[0m'

readonly NUM_CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
readonly LINUX_4_9_51="7b44f96b033c1ec01b4c34350865130058fdb596"

readonly THISDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BASEDIR="/tmp/rpi"
readonly TOOLSDIR="${BASEDIR}/tools"
readonly LINUXDIR="${BASEDIR}/linux"
readonly XENODIR="${BASEDIR}/xenomai"
readonly XENOBUILDDIR="${XENODIR}/build"
readonly XENOINSTALLDIR="${XENODIR}/install"
readonly IPIPEPATCH="${THISDIR}/patches/ipipe-4.9.51-arm.patch"
readonly MODDIR="${BASEDIR}/modules"

error_exit()
{
  echo -e "${RED}$(basename $0): $1${NOCOLOR}" >&2
  popd
  exit 1
}

# Install necessary dependencies
install_deps()
{
  if ! sudo apt-get install -y gcc-4.7-arm-linux-gnueabi libncurses5-dev bc; then
    error_exit "Failed to install build dependencies"
  fi
  # Revoke sudo for improved security.
  sudo -k
}

# Download the Raspberry Pi Linux kernel and Xenomai source.
get_sources()
{
  if ! rm -rf ${BASEDIR}; then
    error_exit "Failed to remove ${BASEDIR}"
  fi

  if ! mkdir -pv ${BASEDIR}; then
    error_exit "Failed to make directory ${BASEDIR}"
  fi

  echo "Cloning Raspberry Pi tools"
  if ! git clone https://github.com/raspberrypi/tools.git ${TOOLSDIR}; then
    error_exit "Failed to clone Raspberry Pi tools"
  fi

  echo "Cloning linux kernel source"
  if ! git clone https://github.com/raspberrypi/linux.git ${LINUXDIR}; then
    error_exit "Failed to clone Raspberry Pi Linux into ${LINUXDIR}"
  fi

  pushd ${LINUXDIR}
  git checkout ${LINUX_4_9_51}
  popd

  echo "Cloning Xenomai source"
  if ! git clone --depth 1 --branch stable-3.0.x https://git.xenomai.org/xenomai-3.git ${XENODIR}; then
    error_exit "Failed to clone Xenomai stable-3.0.x source"
  fi
}

# Uses Xenomai's script to patch the kernel.
prepare_kernel()
{
  echo "Patching linux kernel"
  if ! cd ${LINUXDIR}; then
    error_exit "Failed to cd to linux source tree at ${LINUXDIR}"
  fi

  if ! git reset --hard HEAD; then
    error_exit "Failed to hard-reset linux source code"
  fi

  if ! git clean -fd; then
    error_exit "Failed to clean out linux source tree"
  fi

  if ! cd ${XENODIR}; then
    error_exit "Failed to cd to xenomai source tree at ${XENODIR}"
  fi

  if ! ${XENODIR}/scripts/prepare-kernel.sh --linux="${LINUXDIR}" --ipipe="${IPIPEPATCH}" --arch=arm; then
    error_exit "Xenomai prepare-kernel.sh script failed"
  fi

  # Check for patch rejections.
  local patch_rejections="$(find ${LINUXDIR} -type f -name *.rej | wc -l)";
  if [ "${patch_rejections}" != "0" ]; then
    error_exit "Failed to properly patch system, ${patch_rejections} rejected file(s)"
  fi
}

# Builds an image of the linux kernel.
build_kernel()
{
  KERNEL=kernel7
  cd ${LINUXDIR}
  rm -rf ${MODDIR}

  if ! mkdir ${MODDIR}; then
    error_exit "Failed to make directory ${MODDIR}"
  fi

  local ARM_ARGS=" ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabi- -j${NUM_CORES} "

  echo "Copying default configuration for bcm2709 (Raspberry Pi 2/3)"
  if ! make ${ARM_ARGS} bcm2709_defconfig; then
    error_exit "Failed to make default configuration for Raspberry Pi 3"
  fi

  echo "Launching configuration utility."
  if ! make ${ARM_ARGS} menuconfig; then
    error_exit "Failed to configure through menuconfig"
  fi

  echo "Building Linux"
  if ! make ${ARM_ARGS} zImage modules dtbs; then
    error_exit "Failed to build linux kernel"
  fi

  echo "Installing modules to ${MODDIR}"
  if ! make modules_install ${ARM_ARGS} INSTALL_MOD_PATH=${MODDIR}; then
    error_exit "Failed to make modules_install"
  fi
}

# Cross-compiles the xenomai libraries.
# TODO(RWS): Doesn't package /dev entries.
build_libs()
{
  if ! cd "${XENODIR}"; then
    error_exit "Failed to cd to xenomai source tree at  ${XENODIR}"
  fi

  if ! ./scripts/bootstrap; then
    error_exit "Failed to bootstrap xenomai lib build"
  fi

  rm -rf "${XENOBUILDDIR}"

  if ! mkdir -v "${XENOBUILDDIR}"; then
    error_exit "Failed to mkdir ${XENOBUILDDIR}"
  fi

  if ! cd "${XENOBUILDDIR}"; then
    error_exit "Failed to cd to xenomai build root at ${XENOBUILDDIR}"
  fi

  ${XENODIR}/configure CFLAGS="-march=armv7-a" LDFLAGS="-march=armv7-a" \
            --host=arm-linux-gnueabi \
            --with-core=cobalt \
            --enable-debug=symbols
  if [ $? -ne 0 ]; then
    error_exit "Failed to configure xenomai libs"
  fi

  local pkg="libxenomai"
  sudo checkinstall \
       --arch=armhf \
       --default \
       --install=no \
       --nodoc \
       --pkgname $pkg \
       --pkgsource $pkg \
       --provides $pkg \
       --pkgversion "3.0.6" \
       make install
  if [ $? -ne 0 ]; then
    error_exit "Failed to make install xenomai libs"
  fi
}

main()
{
  pushd .
  install_deps
  get_sources
  prepare_kernel
  build_kernel
  # build_libs
  popd
}

main
