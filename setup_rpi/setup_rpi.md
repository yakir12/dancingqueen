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
works on bookworm...
```
sudo cp /home/yakir/new_projects/dancingqueen/setup_rpi/custom.toml /media/yakir/bootfs/custom.toml
```
finally, unmount:
```
sudo umount /media/yakir/bootfs
sudo rm -rf /media/yakir/bootfs
```
## All in one
Just make sure its sdc first, and that it's unmouted
```
sudo rpi-imager --cli 2023-12-11-raspios-bookworm-arm64-lite.img.xz /dev/sdc
sudo mkdir /media/yakir/bootfs
sudo mount /dev/sdc1 /media/yakir/bootfs 
sudo cp '/home/yakir/from github/dancingqueen/custom.toml' /media/yakir/bootfs/custom.toml
sudo umount /media/yakir/bootfs
sudo rm -rf /media/yakir/bootfs
```

# On the PI
ssh in:
```
ssh <192...>
```
update everything
```
sudo apt-get update
sudo apt-get -y upgrade
sudo reboot -h now
```

install Julia
```
curl -fsSL https://install.julialang.org | sh -s -- --yes --default-channel release
. .bashrc
. .profile
```
ensure the CPU clock does not get throttled during the video capture
```
sudo sed -i 's/force_turbo=0/force_turbo=1/g' /boot/firmware/config.txt
```
close all the lights
```
sudo bash -c 'cat <<EOT >> /boot/config.txt
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
EOT'
```

setup julia environment for the server
```
sudo apt-get -y install git
git clone https://github.com/yakir12/dancingqueen.git
cd dancingqueen/server
julia --project=. -e 'import Pkg; Pkg.develop(path="DancingQueen"); Pkg.instantiate()'
```

make sure it restarts every time you reboot the pi
```
mkdir $HOME/logs
(crontab -l -u yakir 2>/dev/null; echo "@reboot sh $HOME/dancingqueen/server/launcher.sh >$HOME/logs/cronlog 2>&1") | crontab -u yakir -
```

Stop the fan on shutdown:
```
sudo rpi-eeprom-config --edit

# and change
WAKE_ON_GPIO=0
POWER_OFF_ON_HALT=1

# and then reboot
sudo reboot -h now
```

















# This does not work:
Julia needs 4 GB, if this RPI only has 2GB RAM (and not 8 GB) then I increase SWAP to 1 GB, and with zram it increases to 12 BG, together 13 GB. Maybe it'll be enough....
```
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=100/CONF_SWAPSIZE=1024/g' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
sudo apt-get -y install git
git clone https://github.com/foundObjects/zram-swap
cd zram-swap/
sudo ./install.sh
sudo sed -i 's/#_zram_fixedsize="2G"/_zram_fixedsize="12G"/g' /etc/default/zram-swap
sudo systemctl restart zram-swap.service
```
build Julia
```
cd
git clone https://github.com/JuliaLang/julia.git
cd julia
git checkout v1.10.1
make -j4
```
add alias to julia
```
cd
echo "alias julia='$HOME/julia/julia'" >> .bashrc
. .bashrc
```


