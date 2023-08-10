sudo apt-get update
sudo apt-get -y dist-upgrade
# install Julia
curl -fsSL https://install.julialang.org | sh -s -- --yes --default-channel release
# update bash
. /home/pi/.bashrc
# update Julia
julia -e "import Pkg; Pkg.update()"

sudo reboot -h now
