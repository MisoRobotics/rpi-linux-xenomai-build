#!/usr/bin/env bash
#
# Gets the source for Raspberry Pi Linux 4.14, patches it with I-Pipe
# and Xenomai, and builds the kernel.

readonly RED='\033[0;31m'
readonly NOCOLOR='\033[0m'

readonly NUM_CORES=$(cat /proc/cpuinfo | grep processor | wc -l)

readonly BASEDIR="/tmp/rpi"
readonly LINUXDIR="${BASEDIR}/linux"
readonly MODDIR="${BASEDIR}/modules"

error_exit()
{
  echo -e "${RED}$(basename $0): $1${NOCOLOR}" >&2
  popd
  exit 1
}

deploy_kernel()
{
  local bootdir="$1"
  KERNEL=kernel7
  cd ${LINUXDIR}

  echo "Deploying kernel to ${bootdir}"

  if ! cp -v arch/arm/boot/dts/*.dtb ${bootdir}/; then
    error_exit "Failed to copy dtbs to boot directory"
  fi

  if ! cp -v arch/arm/boot/dts/overlays/*.dtb* ${bootdir}/overlays/; then
    error_exit "Failed to copy overlay dtbs to boot directory"
  fi

  if ! cp -v arch/arm/boot/dts/overlays/README ${bootdir}/overlays/; then
    error_exit "Failed to copy overlays README to boot directory"
  fi

  if ! cp -v arch/arm/boot/zImage ${bootdir}/${KERNEL}.img; then
    error_exit "Failed to copy kernel image to boot directory"
  fi
}

main()
{
  pushd .
  deploy_kernel "$1"
  popd
}

main "$1"
