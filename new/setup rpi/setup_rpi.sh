# burn RPI image to SD card
# image: Raspberry Pi OS Lite (64-bit)
# settings: 
# hostname: raspberrypi
# allow public-key auth only
# username: yakir
# SSID: Ermahgerd
# locale TZ: Europe/Stockholm
# locale keyboard: us

sudo apt-get update
sudo apt-get -y dist-upgrade
sudo reboot -h now
# install programs
# sudo apt-get -y install git dnsmasq
sudo apt-get -y install git
# install Julia
curl -fsSL https://install.julialang.org | sh -s -- --yes --default-channel release
# update bash
. $HOME/.bashrc
# setup software

git clone https://github.com/yakir12/dancingqueen.git

# ssh-keyscan github.com >> $HOME/.ssh/known_hosts
# git clone git@github.com:yakir12/dancingqueen.git

cd $HOME/dancingqueen/new

julia --project -e "import Pkg; Pkg.instantiate()"

julia --project --threads auto main.jl

# configure dnsmasq
# echo 'interface=eth0' | sudo tee -a /etc/dnsmasq.conf
# echo 'domain=me.local ' | sudo tee -a /etc/dnsmasq.conf
# echo '192.168.1.17 dancingqueen' | sudo tee -a /etc/hosts
# sudo systemctl restart dnsmasq
