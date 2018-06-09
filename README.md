# rpi-linux-xenomai-build

This repo provides scripts for building Linux 4.9.80 with the latest Xenomai 3.0.x for the Raspberry Pi 3.

## Instructions
1. Clone this repo:
```
git clone https://github.com/MisoRobotics/rpi-linux-xenomai-build.git /tmp/rpi-linux-xenomai-build
```
2. Patch and build the Linux kernel:
```
/tmp/rpi-linux-xenomai-build/build-4.9.sh
```
3. Deploy the kernel to an SD card (assuming you have the boot dir set to the variable below):
```
/tmp/rpi-linux-xenomai-build/deploy-4.9.sh ${RPI_SD_CARD_BOOT_DIR}
```
