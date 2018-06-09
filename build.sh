#!/usr/bin/env bash
#
# Gets the source for Raspberry Pi Linux 4.14, patches it with I-Pipe
# and Xenomai, and builds the kernel.

readonly RED='\033[0;31m'
readonly NOCOLOR='\033[0m'

readonly BASEDIR=/tmp/rpi
readonly LINUXDIR="${BASEDIR}/linux-rpi-4.14"
readonly IPIPEDIR="${BASEDIR}/ipipe"
readonly XENODIR="${BASEDIR}/xenomai"

error_exit()
{
  echo -e "${RED}$(basename $0): $1${NOCOLOR}" >&2
  exit 1
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

  echo "Cloning linux kernel source."
  if ! git clone --depth 1 --branch rpi-4.14.y https://github.com/raspberrypi/linux.git ${LINUXDIR}; then
    error_exit "Failed to clone branch rpi-4.14.y of Raspberry Pi Linux into ${LINUXDIR}"
  fi

  echo "Cloning I-Pipe patch."
  if ! git clone --depth 1 --branch 4.14 https://git.xenomai.org/ipipe-arm.git ${IPIPEDIR}; then
    error_exit "Failed to cone I-Pipe 4.14 for arm source"
  fi

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

  if ! ${XENODIR}/scripts/prepare-kernel.sh --linux="${LINUXDIR}" --ipipe="${IPIPEDIR}" --arch=arm; then
    error_exit "Xenomai prepare-kernel.sh script failed with error code $?"
  fi
}

main()
{
  # get_sources
  prepare_kernel
}

main
