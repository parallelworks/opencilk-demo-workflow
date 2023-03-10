#!/bin/bash
#================================
# Run tests with OpenCilk
#================================

# Download code
git clone https://github.com/opencilk/tutorial

# Compile code
cd tutorial
$HOME/build/bin/clang qsort.c -o qsort -O3 -fopencilk

# Run code
CILK_NWORKERS=8 ./qsort 100000

