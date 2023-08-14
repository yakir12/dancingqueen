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
cd $HOME/dancingqueen/pi
julia --project=. -e "import Pkg; Pkg.instantiate()"

# configure dnsmasq
# echo 'interface=eth0' | sudo tee -a /etc/dnsmasq.conf
# echo 'domain=me.local ' | sudo tee -a /etc/dnsmasq.conf
# echo '192.168.1.17 dancingqueen' | sudo tee -a /etc/hosts
# sudo systemctl restart dnsmasq
