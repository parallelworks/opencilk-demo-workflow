#!/bin/bash
#================================
# Run tests with OpenCilk
#================================

#SBATCH --nodes=1
#SBATCH --exclusive

source ~/.bashrc

# Set inputs
test_name=$1
test_num=$2
test_size=$3
worker_num=$4
result_log=$5

# Check for empty inputs, and if empty, set defaults
[ -z "$test_name" ] && test_name=qsort || echo $test_name
[ -z "$test_num" ] && test_num=100 || echo $test_num
[ -z "$test_size" ] && test_size=1000 || echo $test_size
[ -z "$worker_num" ] && worker_num=4 || echo $worker_num
[ -z "$result_log" ] && result_log=run_cilk_tests.log || echo $result_log

# Tell the user what we're doing
echo Running OpenCilk with ${test_name} ${test_size} for $test_num times with $worker_num workers > $result_log

# Download code
git clone https://github.com/opencilk/tutorial

# Compile code
cd tutorial
clang ${test_name}.c -o ${test_name}.o -O3 -fopencilk
cd ..

# Run code
CILK_NWORKERS=$worker_num
for (( ii=0; ii<$test_num; ii++ ))
do
    ./tutorial/${test_name}.o ${test_size} >> ${result_log}
done

# Create a list of just the times
bn=$(basename ${result_log} .log)
grep Time ${result_log} | awk '{print $3}' > ${bn}.csv
