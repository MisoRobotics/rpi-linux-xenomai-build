# rpi-linux-xenomai-build

This repo provides scripts for building Linux 4.9.51 with the latest Xenomai 3.0.x for the Raspberry Pi 3.

## Build and Deploy the Kernel
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

## Test the Image and Configure Networking
1. Put the Micro SD card in the Raspberry Pi and boot it up with a keyboard, monitor, and ethernet connected.
2. Launch the configuration utility:
```
sudo raspi-config
```
3. Change the keyboard to US instead of the default international.
4. Enable SSH.
5. Exit the configuration utility.

## Build and Install libxenomai
1. Switch back to your desktop.
1.After building and deploying the kernel in the above section, copy xenomai and the build repo to the Raspberry Pi. If you have only one Raspberry Pi on your network and it's accessible through zeroconf, you can do something like:
```
ssh pi@raspberrypi.local mkdir -pv /tmp/rpi
scp -r /tmp/rpi/xenomai pi@raspberrypi.local:/tmp/rpi
scp -r /tmp/rpi-linux-xenomai-build /tmp
```
2. Connect to the Raspberry Pi for the rest of the steps:
````
ssh pi@raspberrypi.local
```
3. Run the `build-libs.sh` script to build and install libxenomai:
```
/tmp/rpi-linux-xenomai-build/build-libs.sh
```
4. Verify that libxenomai is working with the Xenomai Cobalt kernel by running the provided test programming and observing latency below 10 μs:
```
sudo /usr/xenomai/bin/latency
```

## Next Steps
After deploying the kernel and installing libxenomai, you can install ROS on the Raspberry Pi: https://github.com/MisoRobotics/rosberry-pi-setup
