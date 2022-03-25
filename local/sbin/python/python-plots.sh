#!/bin/bash
#set -x

shopt -s expand_aliases
export CRUISE=$1
export DRIVE=$2
. ${DRIVE}/${CRUISE}/local/etc/skel/.bashrc.${CRUISE}
export NC_DIR=netcdf
export PROF_DIR=plots/python
export SECT_DIR=coupes/python
##### CTD plots
echo ' '
echo 'CTD plotting'
CTD
# all profiles
$LOCAL/sbin/python/plots.py $NC_DIR/OS_${CRUISE}_CTD.nc -t CTD -p -k PRES TEMP PSAL DOX2 FLU2 -g -c k- b- r- m- g- -g -o $PROF_DIR

## section 10W
$LOCAL/sbin/python/plots.py $NC_DIR/OS_${CRUISE}_CTD.nc -t CTD -s --append 1N-10W_10S_10W -k PRES TEMP --xaxis LATITUDE -l 15 20 --yscale 0 500 --xinterp 24 --yinterp 200 --clevels=30 --autoscale 0 30 -o $SECT_DIR

#####  XBT plot
echo ' '
echo 'XBT plotting'
XBT
# all profiles
$LOCAL/sbin/python/plots.py $NC_DIR/OS_${CRUISE}_XBT.nc -t XBT -p -k DEPTH TEMP DENS SVEL -c k- b- k- g- -g -o plots

# gc section
#$LOCAL/sbin/python/plots_JG.py $NC_DIR/OS_${CRUISE}_XBT.nc -t XBT -s -k DEPTH TEMP -l 12 30 -xaxis LATITUDE
$LOCAL/sbin/python/plots.py $NC_DIR/OS_${CRUISE}_XBT.nc --type XBT --sections --append CANARIES_1-30N-10W -k DEPTH TEMP --xaxis LATITUDE -l 15 20 --yscale 0 250 250 900 --xinterp 15 --yinterp 10 --clevels=30 --autoscale 0 30 -o $SECT_DIR

#### LADCP plots
echo ' '
echo 'LADCP plotting'
LADCP
# all profiles
$LOCAL/sbin/python/plots.py $NC_DIR/OS_${CRUISE}_ADCP.nc -t ADCP -p -k DEPTH EWCT NSCT -l 15 20 -c k- r- b- -g -o $PROF_DIR
