#!/bin/bash
#set -x 
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
echo "Begin process: `/bin/date +%d/%m/%Y_%H:%M:%S`"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
echo " "
shopt -s expand_aliases
export CRUISE=$1
export CRUISEid=$2
export DRIVE=$3
export CRUISElc=$(echo $CRUISE | tr '[:upper:]' '[:lower:]') #lowercase
export CRUISEidlc=$(echo $CRUISEid | tr '[:upper:]' '[:lower:]') #lowercase

echo "Trying to source ${DRIVE}/${CRUISE}/local/etc/skel/.bashrc.${CRUISE}"
if [ -f ${DRIVE}/${CRUISE}/local/etc/skel/.bashrc.${CRUISE} ]; then
  . ${DRIVE}/${CRUISE}/local/etc/skel/.bashrc.${CRUISE}
  echo "Yes, seems good !!!"
else
  echo "Can't source file !!! check your network, hard drive and/or ENV variables !!!"
fi
# check alias for debug
#alias

  echo ""
  echo "CTD processing:"
  echo "---------------"
  CTD
  ctd
  ctdnc
  ctdall
  ctdallnc
  btl
  btlnc

  echo ""
  echo "TSG processing:"
  echo "---------------"
  TSG
  tsg
  tsgnc
  ctd-tsg

  echo ""
  echo "XBT processing:"
  echo "---------------"
  XBT
  xbt
  xbtnc

  echo ""
  echo "LADCP processing:"
  echo "-----------------"
  LADCP
  ladcp
  ladcpnc

  echo ""
  echo "CASINO processing:"
  echo "------------------"
  CASINO
  casino
  casinonc
  casinosndnc
  casinotsgnc
  casinofboxnc
  
  # plot profiles and sections
  echo ""
  echo "Python plots processing:"
  echo "------------------------"
  
  cd $LOCAL/sbin/python
  python-plots.sh $CRUISE $DRIVE
  cd $LOCAL/sbin/python
  scatter.py
  
  echo ""
  echo "GoogleEarth cruisetrack processing:"
  echo "------------------------------------"
  CTD
  cd tracks
  $LOCAL/sbin/linux/cruiseTrack2kml-linux-amd64 -config ../../local.toml -output $CRUISElc-local.kml 
  #$LOCAL/sbin/linux/cruiseTrack2kml-linux-amd64 -config ../../config.toml -output $CRUISElc.kml 

echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
echo "End of process : `/bin/date +%d/%m/%Y_%H:%M:%S`"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
