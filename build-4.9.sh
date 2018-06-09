#!/usr/bin/env bash
#
# Gets the source for Raspberry Pi Linux 4.14, patches it with I-Pipe
# and Xenomai, and builds the kernel.

readonly RED='\033[0;31m'
readonly NOCOLOR='\033[0m'

readonly THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly BASEDIR=/tmp/rpi
readonly TOOLSDIR="${BASEDIR}/tools"
readonly LINUXDIR="${BASEDIR}/linux"
readonly XENODIR="${BASEDIR}/xenomai"
readonly IPIPEPATCH="${THISDIR}/patches/ipipe-core-4.9.80-arm-5.patch"
readonly MODDIR="${BASEDIR}/modules"

readonly FIRMWARE="5db8e4e1c63178e200d6fbea23ed4a9bf4656658"

readonly BOOTDIR="/media/rsinnet/boot"

error_exit()
{
  echo -e "${RED}$(basename $0): $1${NOCOLOR}" >&2
  popd
  exit 1
}

install_deps()
{
  sudo apt-get install -y gcc-4.7-arm-linux-gnueabi libncurses5-dev
}

get_sources()
{
  if ! rm -rf ${BASEDIR}; then
    error_exit "Failed to remove ${BASEDIR}"
  fi

  if ! mkdir -pv ${BASEDIR}; then
    error_exit "Failed to make directory ${BASEDIR}"
  fi

  cd ${BASEDIR}

  echo "Cloning Raspberry Pi tools."
  if ! git clone https://github.com/raspberrypi/tools.git ${TOOLSDIR}; then
    error_exit "Failed to clone Raspberry Pi tools"
  fi

  echo "Cloning linux kernel source."
  if ! git clone https://github.com/raspberrypi/linux.git ${LINUXDIR}; then
    error_exit "Failed to clone Raspberry Pi Linux into ${LINUXDIR}"
  fi

  cd ${LINUXDIR}

  echo "Cloning Xenomai source."
  if ! git clone --depth 1 --branch stable-3.0.x https://git.xenomai.org/xenomai-3.git ${XENODIR}; then
    error_exit "Failed to clone Xenomai stable-3.0.x source"
  fi
}

prepare_kernel()
{
  echo "Patching linux kernel."
  if ! cd ${XENODIR}; then
    error_exit "Failed to cd to xenomai source tree at ${XENODIR}"
  fi

  if ! ${XENODIR}/scripts/prepare-kernel.sh --linux="${LINUXDIR}" --ipipe="${IPIPEPATCH}" --arch=arm; then
    error_exit "Xenomai prepare-kernel.sh script failed"
  fi
}

build_kernel()
{
  KERNEL=kernel7
  cd ${LINUXDIR}
  rm -rf ${MODDIR}

  if ! mkdir ${MODDIR}; then
    error_exit "Failed to make directory ${MODDIR}"
  fi

  if ! make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabi- bcm2709_defconfig -j20; then
    error_exit "Failed to make default configuration for Raspberry Pi 3."
  fi

  if ! make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabi- -j20 zImage modules dtbs; then
    error_exit "Failed to build linux kernel"
  fi

  if ! make modules_install ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabi- INSTALL_MOD_PATH=${MODDIR} -j20; then
    error_exit "Failed to make modules_install"
  fi

  if ! cp arch/arm/boot/dts/*.dtb ${BOOTDIR}/; then
    error_exit "Failed to copy dtbs to boot directory"
  fi
  if ! cp arch/arm/boot/dts/overlays/*.dtb* ${BOOTDIR}/overlays/; then
    error_exit "Failed to copy overlay dtbs to boot directory"
  fi

  if ! cp arch/arm/boot/dts/overlays/README ${BOOTDIR}/overlays/; then
    error_exit "Failed to copy overlays README to boot directory"
  fi

  if ! cp arch/arm/boot/zImage ${BOOTDIR}/${KERNEL}.img; then
    error_exit "Failed to copy kernel image to boot directory"
  fi
}

install_ros()
{
  sudo apt-get install -y \
       python-catkin-pkg \
       python-rosdep \
       python-rosinstall-generator \
       python-wstool \
       python-rosinstall \
       build-essential \
       cmake
}

main()
{
  pushd .
  if ! sudo --validate; then
    error_exit "Failed to obtain elevated permissions"
  fi
  #get_sources
  prepare_kernel
  build_kernel
  popd
}

main
