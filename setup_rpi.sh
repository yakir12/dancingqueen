# you might need to format the SD card to ext4
# download the Raspberry Pi OS (Legacy, 64-bit, Lite) from https://www.raspberrypi.com/software/operating-systems/
wget https://downloads.raspberrypi.com/raspios_oldstable_lite_arm64/images/raspios_oldstable_lite_arm64-2023-12-06/2023-12-05-raspios-bullseye-arm64-lite.img.xz?_gl=1*18b0jzg*_ga*NTAwMDgyMzMzLjE2OTI2OTQ4OTk.*_ga_22FD70LWDS*MTcwODUyMDcwMy4xNS4xLjE3MDg1MjA3NTUuMC4wLjA. -O image
# identify which drive device it is, /dev/sdc?
sudo rpi-imager --cli image /dev/sdc

# I had to use rpi-imager to maually burn the correct image onto the SD card, but then I could turn ssh on, set the wifi correctly, and locale etc...

# Prepare the pi for headless login on first boot
# ssh
touch /media/yakir/bootfs/ssh
# wifi
cat <<EOT >> /media/yakir/bootfs/wpa_supplicant.conf
country=SE
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="Ermahgerds"
    psk="is it though, isn't it just Steven"
}
EOT
# and user
echo "pi:$6$.Jk7LkjEPjxPPmGE$gapTdsLwqOZJSLbh3LXbt6UelmRKv1ezh3y3vITsIA.TPFxsdFdM/3259WWsUUhHmd/dc6Zer0ZcZ6q3FSrSV." >> /media/yakir/bootfs/userconf.txt

# on the pi
sudo apt-get update
sudo apt-get -y upgrade
sudo reboot -h now

# ensure the CPU clock does not get throttled during the video capture
sudo sed -i 's/force_turbo=0/force_turbo=1/g' /boot/firmware/config.txt

# close all the lights
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

# install Julia
sudo apt-get -y install git
git clone https://github.com/JuliaLang/julia.git
cd julia
git checkout v1.10.1
make -j4
cd

# add alias to julia
echo "alias julia='$HOME/julia/julia'" >> .bashrc
. .bashrc

# setup julia environment for the server
git clone https://github.com/yakir12/dancingqueen.git
cp -r dancingqueen/new3/server .
rm -rf dancingqueen

cd server
julia --project=. -e "import Pkg; Pkg.instantiate()"

