sudo apt-get update
sudo apt-get -y dist-upgrade
sudo reboot -h now
# install programs
sudo apt-get -y install git
# install Julia
curl -fsSL https://install.julialang.org | sh -s -- --yes --default-channel release
# update bash
. /home/pi/.bashrc
# setup software
git clone https://github.com/yakir12/dancingqueen.git
cd dancingqueen/pi
julia --project=. -e "import Pkg; Pkg.instantiate()"
