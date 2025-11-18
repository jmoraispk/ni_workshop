#!/usr/bin/env bash
set -euo pipefail

echo "=== OAI/USRP/GNU Radio workshop setup script ==="
echo "This will install a lot of packages and build UHD, GNU Radio, gr-osmosdr, gr-rds, and gqrx from source."
echo "You should be on Ubuntu/Xubuntu 22.04.x and have sudo access."

HOME=/home
echo ">>> Using base directory: $HOME"

#-----------------------------
# Step 3: Update & upgrade
#-----------------------------
echo ">>> Updating and upgrading packages..."
sudo apt update
sudo apt -y upgrade

#-----------------------------
# Step 4: Install dependencies
# (Note: libVtw3-* from the PDF is almost certainly libfftw3-*)
#-----------------------------
echo ">>> Installing build and runtime dependencies (this may take a while)..."

sudo apt install tzdata -y  # move dependency up so the user can relax the rest of the time...

sudo apt-get install -y \
  autoconf automake build-essential ccache cmake cpufrequtils \
  doxygen ethtool g++ git inetutils-tools libboost-all-dev \
  libncurses5 libncurses5-dev libusb-1.0-0 libusb-1.0-0-dev libusb-dev \
  python3-dev python3-mako python3-numpy python3-requests \
  python3-scipy python3-setuptools python3-ruamel.yaml

sudo apt install -y \
  git cmake g++ libboost-all-dev libgmp-dev swig python3-numpy \
  python3-mako python3-sphinx python3-lxml doxygen \
  libfftw3-dev libsdl1.2-dev libgsl-dev libqwt-qt5-dev libqt5opengl5-dev \
  python3-pyqt5 liblog4cpp5-dev libzmq3-dev python3-yaml \
  python3-click python3-click-plugins python3-zmq python3-scipy \
  python3-gi python3-gi-cairo gir1.2-gtk-3.0 libcodec2-dev libgsm1-dev \
  libusb-1.0-0 libusb-1.0-0-dev libudev-dev python3-setuptools

sudo apt install -y \
  openssh-server htop tree lshw meld libfftw3-bin \
  ncurses-bin libncurses6 libncursesw6 libvolk2-dev curl

#-----------------------------
# Step 5: git directory
#-----------------------------
echo ">>> Creating \$HOME/git..."
mkdir -p "$HOME/git"

#-----------------------------
# Step 6: workarea directory
#-----------------------------
echo ">>> Creating \$HOME/workarea..."
mkdir -p "$HOME/workarea"

#-----------------------------
# Step 7: Download workshop materials
#-----------------------------
echo ">>> Downloading workshop materials and slides..."
wget -P "$HOME/workarea" \
  https://kb.ettus.com/images/a/ab/Workshop_GnuRadio_Materials_20171212.tar.gz

wget -P "$HOME/workarea" \
  https://kb.ettus.com/images/f/fd/Workshop_GnuRadio_Slides_20250802.pdf

#-----------------------------
# Step 8: Unpack materials
#-----------------------------
echo ">>> Unpacking workshop materials..."
cd "$HOME/workarea"
tar zxvf Workshop_GnuRadio_Materials_20171212.tar.gz

#-----------------------------
# Step 9: Install UHD v4.2.0.0 and images
#-----------------------------
echo ">>> Fetching and building UHD v4.2.0.0 from tarball..."
cd "$HOME/git"

if [ ! -d uhd ]; then
  # Clean any leftovers
  rm -rf uhd uhd-4.2.0.0 uhd-4.2.0.0.tar.gz

  # Download the exact UHD release tarball
  curl -L https://github.com/EttusResearch/uhd/archive/refs/tags/v4.2.0.0.tar.gz -o uhd-4.2.0.0.tar.gz

  # Unpack and rename to "uhd" so the rest of the script works
  tar xzf uhd-4.2.0.0.tar.gz
  mv uhd-4.2.0.0 uhd
fi

cd uhd/host
rm -rf build
mkdir -p build
cd build
cmake ../
make -j"$(nproc)"
sudo make install
sudo ldconfig

echo ">>> Downloading USRP FPGA images..."
sudo uhd_images_downloader

echo ">>> Downloading USRP FPGA images..."
sudo uhd_images_downloader

#-----------------------------
# Step 10: Install GNU Radio v3.8.5.0
#-----------------------------
echo ">>> Cloning and building GNU Radio v3.8.5.0..."
cd "$HOME/git"

if [ ! -d gnuradio ]; then
  # Clean any leftovers
  rm -rf gnuradio gnuradio-3.8.5.0 gnuradio-3.8.5.0.tar.gz

  # Download the exact release tarball
  curl -L https://github.com/gnuradio/gnuradio/archive/refs/tags/v3.8.5.0.tar.gz \
    -o gnuradio-3.8.5.0.tar.gz

  # Unpack and rename to "gnuradio" so the rest of the script works
  tar xzf gnuradio-3.8.5.0.tar.gz
  mv gnuradio-3.8.5.0 gnuradio
fi

cd gnuradio
rm -rf build
mkdir -p build
cd build

# PATCH: because we got gnuradio from a tarball,... we need to link VOLK manually
VOLK_CONFIG="$(dpkg -L libvolk2-dev | grep -m1 VolkConfig.cmake || true)"
VOLK_DIR="$(dirname "$VOLK_CONFIG")"
cmake -DVolk_DIR="$VOLK_DIR" -DENABLE_INTERNAL_VOLK=OFF ../
make -j"$(nproc)"
sudo make install
sudo ldconfig

#-----------------------------
# Step 11: Update .bashrc environment
#-----------------------------
echo ">>> Appending environment variables to \$HOME/.bashrc..."
echo "Not necessary in container!"

#-----------------------------
# Step 12: Apply USB udev rules
# (not necessary since a) the containers runs as root (rules not needed); 
# b) usb devices in file are available; c) --network host
#-----------------------------
echo ">>> Applying UHD udev rules..."
echo "Not necessary in container!"
#-----------------------------
# Step 13: Install gr-osmosdr (gr3.8)
#-----------------------------
echo ">>> Fetching and building gr-osmosdr (gr3.8) from tarball..."
cd "$HOME/git"
if [ ! -d gr-osmosdr ]; then
  rm -rf gr-osmosdr gr-osmosdr-gr3.8 gr-osmosdr-gr3.8.tar.gz

  curl -L https://github.com/osmocom/gr-osmosdr/archive/refs/heads/gr3.8.tar.gz \
    -o gr-osmosdr-gr3.8.tar.gz

  tar xzf gr-osmosdr-gr3.8.tar.gz
  mv gr-osmosdr-gr3.8 gr-osmosdr
fi

cd gr-osmosdr
rm -rf build
mkdir -p build
cd build
cmake ../
make -j"$(nproc)"
sudo make install
sudo ldconfig

#-----------------------------
# Step 14: Install gr-rds (maint-3.8)
#-----------------------------
echo ">>> Fetching and building gr-rds (maint-3.8) from tarball..."
cd "$HOME/git"
if [ ! -d gr-rds ]; then
  rm -rf gr-rds gr-rds-maint-3.8 gr-rds-maint-3.8.tar.gz

  curl -L https://github.com/bastibl/gr-rds/archive/refs/heads/maint-3.8.tar.gz \
    -o gr-rds-maint-3.8.tar.gz

  tar xzf gr-rds-maint-3.8.tar.gz
  mv gr-rds-maint-3.8 gr-rds
fi

cd gr-rds
rm -rf build
mkdir -p build
cd build
cmake ../
make -j"$(nproc)"
sudo make install
sudo ldconfig

#-----------------------------
# Step 15: Install GQRX v2.16
#-----------------------------
echo ">>> Installing extra Qt SVG dependencies for gqrx..."
sudo apt-get install -y libqt5svg5 libqt5svg5-dev

echo ">>> Fetching and building gqrx v2.16 from tarball..."
cd "$HOME/git"
if [ ! -d gqrx ]; then
  rm -rf gqrx gqrx-2.16 gqrx-2.16.tar.gz

  curl -L https://github.com/gqrx-sdr/gqrx/archive/refs/tags/v2.16.tar.gz \
    -o gqrx-2.16.tar.gz

  tar xzf gqrx-2.16.tar.gz
  mv gqrx-2.16 gqrx
fi

cd gqrx
rm -rf build
mkdir -p build
cd build
cmake ../
make -j"$(nproc)"
sudo make install
sudo ldconfig

echo "=== Setup complete. ==="
echo "You should now have UHD, GNU Radio 3.8.5, gr-osmosdr, gr-rds, and gqrx installed."
