#!/usr/bin/env bash
#
# Builds Xenomai on the Raspberry Pi.

readonly WHITE='\033[37;1m'
readonly REDBOLD='\033[31;1m'
readonly NOCOLOR='\033[0m'

readonly NUM_CORES="$(grep -c ^processor /proc/cpuinfo)"
readonly ARCH="$(dpkg --print-architecture)"
readonly BASEDIR="/tmp/rpi"
readonly XENODIR="${BASEDIR}/xenomai"
readonly XENOBUILDDIR="${XENODIR}/build"

error_exit()
{
  echo -e "${REDBOLD}$(basename $0)${NOCOLOR}:${WHITE} $1${NOCOLOR}" >&2
  popd
  exit 1
}

# Checks that this is being run on the correct system.
check_system()
{
  if [ "${ARCH}" != "armhf" ]; then
    error_exit "The current architecture (${ARCH}) is not supported"
  fi
}

# Increases the size of swap memory for building ROS in parallel.
configure_swap()
{
    if ! sudo -H sed -i 's/\(CONF_SWAPSIZE=\)[0-9]\+/\12048/g' /etc/dphys-swapfile; then
      error_exit "Failed to modify swap file configuration"
    fi

    if ! sudo dphys-swapfile setup; then
      sudo dphys-swapfile swapon
      error_exit "Failed to reconfigure swap file"
    fi

    if ! sudo dphys-swapfile swapon; then
      error_exit "Failed to enable swap. Try sudo dphys-swapfile swapon."
    fi
}

# Install necessary dependencies.
install_deps()
{
  echo "Installing build dependencies."
  sudo apt-get install -y \
       autoconf \
       checkinstall \
       libtool
  if [ $? -ne 0 ]; then
    error_exit "Failed to install build dependencies"
  fi
}

# Compiles the xenomai libraries.
build_libs()
{
  if ! cd "${XENODIR}"; then
    error_exit "Failed to cd to xenomai source tree at ${XENODIR}, did you copy the repo from your desktop?"
  fi

  if ! ./scripts/bootstrap; then
    error_exit "Failed to bootstrap libxenomai build at source tree ${XENODIR}"
  fi

  if ! sudo rm -rf "${XENOBUILDDIR}"; then
    error_exit "Failed to rmdir ${XENOBUILDDIR}"
  fi

  if ! mkdir -v "${XENOBUILDDIR}"; then
    error_exit "Failed to mkdir ${XENOBUILDDIR}"
  fi

  if ! cd "${XENOBUILDDIR}"; then
    error_exit "Failed to cd to xenomai build root at ${XENOBUILDDIR}"
  fi

  ${XENODIR}/configure CFLAGS="-march=armv7-a" LDFLAGS="-march=armv7-a" \
            --with-core=cobalt \
            --enable-debug=symbols \
            --enable-smp
  if [ $? -ne 0 ]; then
    error_exit "Failed to configure libxenomai from source tree ${XENODIR}"
  fi

  if ! make -j${NUM_CORES}; then
    error_exit "Failed to build libxenomai in build dir ${XENOBUILDDIR}"
  fi

  if ! sudo -H make install; then
    error_exit "Failed to make install libxenomai in build dir ${XENOBUILDDIR}}"
  fi
}

main()
{
  pushd .
  check_system
  configure_swap
  install_deps
  build_libs
  popd
}

main
