#!/bin/bash
export CRUISE="PIRATA-FR27"
export DRIVE="/data/"
export CONFIG=pirata-fr27.toml
export PREFIX=fr27
${DRIVE}${CRUISE}/local/sbin/linux/oceano2oceansites -c ${DRIVE}${CRUISE}/data-processing/${CONFIG} -r ${DRIVE}${CRUISE}/local/code_roscop.csv -e --files=${DRIVE}${CRUISE}/data-processing/CTD/data/cnv/${PREFIX}*.cnv --output=${DRIVE}${CRUISE}/data-processing/CTD
#echo linux/oceano2oceansites -c ${DRIVE}${CRUISE}/data-processing/${CONFIG} -r ${DRIVE}${CRUISE}/local/code_roscop.csv -e -a --files=${DRIVE}${CRUISE}/data-processing/CTD/data/cnv/${PREFIX}*.cnv --output=${DRIVE}${CRUISE}/data-processing/CTD
