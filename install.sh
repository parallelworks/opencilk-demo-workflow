#!/bin/bash
#============================
# Install OpenCilk (compiling
# from source).  Since this
# is for RHEL7, also need to
# install CMake from source.
#============================

# Install gcc7.3.1, OpenCilk requires gcc5.1+
sudo yum install -y devtoolset-7

# Download CMake source
wget https://github.com/Kitware/CMake/releases/download/v3.25.3/cmake-3.25.3.tar.gz
tar -xvzf cmake-3.25.3.tar.gz

# Build CMake
cd cmake-3.25.3
echo './bootstrap && make && sudo make install' | scl enable devtoolset-7 bash

# Download OpenCilk source
git clone -b opencilk/v2.0 https://github.com/OpenCilk/infrastructure
infrastructure/tools/get $(pwd)/opencilk

# Build OpenCilk
echo 'infrastructure/tools/build $(pwd)/opencilk $(pwd)/build' | scl enable devtoolset-7 bash

