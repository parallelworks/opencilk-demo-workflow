#!/bin/bash

#===============================
# Initializaton
#===============================
# Exit if any command fails!
# Sometimes workflow runs fine but there are SSH problems.
# This line is useful for debugging but can be commented out.
set -e

# Useful info for context
date
jobdir=${PWD}
jobnum=$(basename ${PWD})
ssh_options="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
wfname=opencilk-demo-workflow

echo Starting $wfname workflow...
echo Execution is in main.sh, launched from the workflow.xml.
echo Running in $jobdir with job number: $jobnum
echo

#===============================
# Inputs from workflow.xml
#===============================

echo ==========================================================
echo INPUT ARGUMENTS:
echo ==========================================================
echo $@

#----------HELPER FUNCTIONS-----------
# Function to read arguments in format "--pname pval" into
# export WFP_<pname>=<pval>.  All varnames are prefixed
# with WFP_ to designate workflow parameter.
f_read_cmd_args(){
    index=1
    args=""
    for arg in $@; do
	prefix=$(echo "${arg}" | cut -c1-2)
	if [[ ${prefix} == '--' ]]; then
	    pname=$(echo $@ | cut -d ' ' -f${index} | sed 's/--//g')
	    pval=$(echo $@ | cut -d ' ' -f$((index + 1)))
	    # To support empty inputs (--a 1 --b --c 3)
	    # Empty inputs are ignored and no env var is assigned.
	    if [ ${pval:0:2} != "--" ]; then
		echo "export WFP_${pname}=${pval}" >> $(dirname $0)/env.sh
		export "WFP_${pname}=${pval}"
	    fi
	fi
	index=$((index+1))
    done
}

# Function to print date alongside with message.
echod() {
    echo $(date): $@
    }

# Testing echod
echod Testing echod. Currently on `hostname`.

# Convert command line inputs to environment variables.
f_read_cmd_args $@

# List of input arguments converted to environment vars:
echo "====== Environment variables passed from workflow.xml ======"
env | grep WFP_
echo "================ Done with env. var. list =================="

# Autodetect user
if [ ${WFP_wuser} = "__USER__" ]
then
    echod Changing $WFP_wuser to ${PW_USER}
    export WFP_wuser=${PW_USER}
    echod WFP_wuser is $WFP_wuser
fi

echod Will excute workflow on remote as $WFP_wuser@$WFP_whost

# Check if there are spaces in runcmd:
if [ ${WFP_spaces_in_runcmd} = "False" ]
then
    echod No spaces in runcmd, proceed as normal.
else
    echod There are spaces in runcmd, need to change _ to space.
    echod Original runcmd: $WFP_runcmd
    runcmd_tmp=$WFP_runcmd
    export WFP_runcmd=$(echo ${runcmd_tmp} | sed 's/_/ /g')
    echod Filtered runcmd: $WFP_runcmd
fi

#===============================
# Run the workflow
#===============================
echo
echo ==========================================================
echo Running workflow
echo ==========================================================
echo

# Everything that follows "ssh user@host" is a command executed on the host.
# If the host is a cluster head node, then for SLURM clusters, srun/sbatch 
# sends the execution to a compute node. For PBS clusters, qsub is used.
# The sbatch --wrap option allows for multiple commands (changing to the
# work directory, then launching the job). Sleep commands are inserted to
# simulate long running jobs.

echod "Check connection to cluster"
# This command only talks to the head node, removed -f; no
# need to run in the background.
ssh ${ssh_options} $WFP_wuser@$WFP_whost hostname

echod "Install OpenCilk on a compute node"
ssh -f ${ssh_options} $WFP_wuser@$WFP_whost sbatch --output=${WFP_rundir}/std.out.install --wrap "\"git clone https://github.com/parallelworks/opencilk-demo-workflow; ./opencilk-demo-workflow/install.sh\""

# Wait a bit for the job to get started and register in
# the queue.
sleep ${WFP_sleep_time}

echod "Monitoring status of the build"
# Check if there are any other running jobs on the cluster
# by counting the number of lines in squeue output. One
# line is the header line => no jobs are running.  Anything
# more than 1 means that there is at least one job running.
n_jobs="2"
while [ $n_jobs -gt 1 ]
do
    n_jobs=$(ssh ${ssh_options} $WFP_wuser@$WFP_whost squeue -u $WFP_wuser | wc -l )
    echod "Found "${n_jobs}" lines in squeue."
    echod "Will wait "${WFP_sleep_time}" seconds."
    sleep ${WFP_sleep_time}
done
echod "OpenCilk build finished."
    
echo "Stage back install log file"
# Although SSH implicitly adds a username, rsync requires
# explicit listing of the username.
rsync ${WFP_wuser}@${WFP_whost}:${WFP_rundir}/std.out.install ./

echo Done!

