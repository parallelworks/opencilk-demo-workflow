#!/bin/bash
#============================
# Install OpenCilk (compiling
# from source).  Since this
# is for RHEL7, also need to
# install CMake from source.
#============================

# Select where to install everything.
# /var/lib/pworks is persistent on cloud images
# $HOME, although persistent, is not a good choice
# if you want to make an image since there are 
# permissions issues. On the other hand, if you
# want to share the results of the build with all
# the other nodes in the cluster, $HOME is a good
# starting point.
#install_dir="/home/$PW_USER/pworks"
install_dir="/var/lib/pworks"
sudo mkdir -p $install_dir
sudo chmod a+rwx --recursive $install_dir
cd $install_dir

# Sometimes software collection managers are not 
# already installed on the image.
sudo yum install -y centos-release-scl

# Install gcc7.3.1, OpenCilk requires gcc5.1+
sudo yum install -y devtoolset-7

# Download CMake source, OpenCilk requires 3.18+
wget https://github.com/Kitware/CMake/releases/download/v3.25.3/cmake-3.25.3.tar.gz
tar -xvzf cmake-3.25.3.tar.gz

# Build CMake
cd cmake-3.25.3
echo Building CMake...
time echo './bootstrap --parallel=32 && make -j 32 && sudo make install' | scl enable devtoolset-7 bash

# Download OpenCilk source
cd $install_dir
git clone -b opencilk/v2.0 https://github.com/OpenCilk/infrastructure
infrastructure/tools/get $(pwd)/opencilk

echo Building OpenCilk...
time echo 'infrastructure/tools/build $(pwd)/opencilk $(pwd)/build' | scl enable devtoolset-7 bash

# Ensure all users have access
sudo chmod a+rwx --recursive $install_dir
