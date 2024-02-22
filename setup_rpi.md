# On my computer
## Flash and prepare the SD card
download the Raspberry Pi OS 64-bit, Lite (not Legacy!) from [the Raspberry Pi site](https://www.raspberrypi.com/software/operating-systems/)
```
wget <link>
```
identify which drive device it is, `/dev/sdc`?
flash the image on to the SD card
```
sudo rpi-imager --cli 2023-12-11-raspios-bookworm-arm64-lite.img.xz /dev/sdc
```
pull out and put in the SD card to remount it, or (haven't tried it yet):
```
sudo mkdir /media/yakir/bootfs
sudo mount /dev/sdc1 /media/yakir/bootfs 
```
## Prepare the pi for wifi headless login on first boot
ssh
```
touch /media/yakir/bootfs/ssh
```
wifi
```
cat <<EOT >> /media/yakir/bootfs/wpa_supplicant.conf
country=SE
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="Ermahgerds"
    psk="is it though, isn't it just Steven"
    key_mgmt=WPA-PSK
}
EOT
```
and user
```
echo "pi:$(echo 'raspberry' | openssl passwd -6 -stdin)" > /media/yakir/bootfs/userconf
```
finally, unmount:
```
sudo umount /media/yakir/bootfs /media/yakir/rootfs
```
### All in one:
```
touch /media/yakir/bootfs/ssh
cat <<EOT >> /media/yakir/bootfs/wpa_supplicant.conf
country=SE
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="Ermahgerds"
    psk="is it though, isn't it just Steven"
    key_mgmt=WPA-PSK
}
EOT
echo "pi:$(echo 'raspberry' | openssl passwd -6 -stdin)" > /media/yakir/bootfs/userconf
sudo umount /media/yakir/bootfs
```
# On the PI
ssh in:
```
ssh pi@<192...>
```
password: raspberry

update everything
```
sudo apt-get update
sudo apt-get -y upgrade
sudo reboot -h now
```
ensure the CPU clock does not get throttled during the video capture
```
sudo sed -i 's/force_turbo=0/force_turbo=1/g' /boot/firmware/config.txt
```

close all the lights
```
sudo cat <<EOT >> /boot/config.txt
[pi4]
# Disable the PWR LED
dtparam=pwr_led_trigger=none
dtparam=pwr_led_activelow=off
# Disable the Activity LED
dtparam=act_led_trigger=none
dtparam=act_led_activelow=off
# Disable ethernet port LEDs
dtparam=eth_led0=4
dtparam=eth_led1=4
EOT
```

install Julia
```
sudo apt-get -y install git
git clone https://github.com/JuliaLang/julia.git
cd julia
git checkout v1.10.1
make -j4
cd
```

add alias to julia
```
echo "alias julia='$HOME/julia/julia'" >> .bashrc
. .bashrc
```

setup julia environment for the server
```
git clone https://github.com/yakir12/dancingqueen.git
cd dancingqueen/server
julia --project=. -e "import Pkg; Pkg.instantiate()"
```

