#!/bin/bash
#============================
# Install OpenCilk (compiling
# from source).  Since this
# is for RHEL7, also need to
# install CMake from source.
#============================

# Select where to install everything.
# /var/lib/ is persistent on cloud images
# $HOME, although persistent, is not a good choice
# since there are permissions issues.
install_dir="/var/lib/pworks"
sudo mkdir -p $install_dir
sudo chmod a+rwx --recursive $install_dir
cd $install_dir

# Install gcc7.3.1, OpenCilk requires gcc5.1+
sudo yum install -y devtoolset-7

# Download CMake source, OpenCilk requires 3.18+
wget https://github.com/Kitware/CMake/releases/download/v3.25.3/cmake-3.25.3.tar.gz
tar -xvzf cmake-3.25.3.tar.gz

# Build CMake
cd cmake-3.25.3
echo Building CMake...
time echo './bootstrap && make && sudo make install' | scl enable devtoolset-7 bash

# Download OpenCilk source
git clone -b opencilk/v2.0 https://github.com/OpenCilk/infrastructure
infrastructure/tools/get $(pwd)/opencilk

echo Building OpenCilk...
time echo 'infrastructure/tools/build $(pwd)/opencilk $(pwd)/build' | scl enable devtoolset-7 bash

# Ensure all users have access
sudo chmod a+rwx --recursive $install_dir
