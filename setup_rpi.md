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
cat <<EOT >> /media/yakir/bootfs/custom.toml
# Raspberry Pi First Boot Setup
[system]
hostname = "rpihost"

[user]
name = "yakir"
password = "raspberry"
password_encrypted = false

[ssh]
enabled = true
authorized_keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCvWDWmVSoNauNSy/H2PWYQ729tfD2o3RL6D/9ZdZ4O0J/UJshx/frseqFwjiVJTEisojMVL+Il+o14Tr1p3fyMJu/3YA/+bxRK4S0sW2OUeDOyn82P+Byg9RtuFuO57HrDUaInCqKmqtzgAAZiiCFYBNcB11yT1qd0p5BWqQpE6uMWPXu6gRYjR94NMNmveOATwdbqQkhd1fpxagCGC6NuMCc6OiJjCtHPmGw4hhlQvBL0bdBewardWtvomuqnH9ZBwnoqVtc4lvfMZIL7BG3h1P+UdD8XhIi4ixf5H8ShHWt2vRTSyxKjjLHC3mkAJPEHEr8HZtfOQGwlgvCKmf5L yakir@qbi-lat" ]
# this seems to broken in RPi's "init_config" and it sets "-k" instead of "-p"
# password_authentication = true

[wlan]
country = "se"
ssid = "Ermahgerds"
password = "is it though, isn't it just Steven"
password_encrypted = false
hidden = false

[locale]
keymap = "us"
timezone = "Europe/Stockholm"
EOT
```
finally, unmount:
```
sudo umount /media/yakir/bootfs /media/yakir/rootfs
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

install Julia
```
sudo apt-get -y install git
git clone https://github.com/foundObjects/zram-swap
cd zram-swap/
sudo ./install.sh
cd
git clone https://github.com/JuliaLang/julia.git
cd julia
git checkout v1.10.1
make
```

add alias to julia
```
cd
echo "alias julia='$HOME/julia/julia'" >> .bashrc
. .bashrc
```

setup julia environment for the server
```
git clone https://github.com/yakir12/dancingqueen.git
cd dancingqueen/server
julia --project=. -e "import Pkg; Pkg.instantiate()"
```

