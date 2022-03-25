#!/bin/bash
#
# Mission RESILIENCE N/O Marion Dufresne fevrier 2022 P.Rousselot (J. Grelet)
# script de synchronisation des donnees navire sur mission data-raw et data-processing

# /m -> /mnt/campagnes 
# /q -> /mnt/q
# lancer:
# > sudo bash /mnt/campagnes/RESILIENCE/local/sbin/synchro.sh

# repertoires source
export SOURCE=/Users/gcambon/DATA/CRUISES/RESILIENCE/data-raw/PC-ACQUISITION
export SONDEURS=/Users/gcambon/DATA/CRUISES/RESILIENCE/data-raw/PC-ACQUISITION
export CRUISE=$1
export DRIVE=$2
export CRUISEid=$3
# repertoire de destination
export DEST=$DRIVE/$CRUISE
# nom utilise par genavir a bord pour la campagne
export CRUISENvessel=$(echo $CRUISE | sed 's/-//')	
export mydate=$(date +'%Y') 

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
echo "Debut de synchro : `/bin/date +%d/%m/%Y_%H:%M:%S`"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo " "
# # copie SADCP vers data-raw et data-processing
# echo "# copie SADCP vers data-raw et data-processing"
# /bin/cp -rupv $SONDEURS/$CRUISENvessel/ADCP/OS75/DONNEES/* $DEST/data-raw/SADCP/OS75
# /bin/cp -rupv $SONDEURS/$CRUISENvessel/ADCP/OS75/DONNEES/*.[L-S]TA $DEST/data-processing/SADCP/OS75/data
# # OS150
# /bin/cp -rupv $SONDEURS/$CRUISENvessel/ADCP/OS150/DONNEES/* $DEST/data-raw/SADCP/OS150
# /bin/cp -rupv $SONDEURS/$CRUISENvessel/ADCP/OS150/DONNEES/*.[L-S]TA $DEST/data-processing/SADCP/OS150/data
# # LOCH RDI DVL600
# /bin/cp -rupv $SONDEURS/$CRUISENvessel/LOCH/ANNEXES/* $DEST/data-raw/SADCP/DVL600/ANNEXES
# /bin/cp -rupv $SONDEURS/$CRUISENvessel/LOCH/DONNEES/* $DEST/data-raw/SADCP/DVL600
# /bin/cp -rupv $SONDEURS/$CRUISENvessel/LOCH/DONNEES/*.[L-S]TA $DEST/data-processing/SADCP/DVL600/data

# echo "# cat SADCP files"
# echo "  cat OS75 STA"
# cat $DEST/data-processing/SADCP/OS75/data/*.STA > $DEST/data-processing/SADCP/OS75/STA/$CRUISEid-OS75.STA
# echo "  cat OS75 LTA"
# cat $DEST/data-processing/SADCP/OS75/data/*.LTA > $DEST/data-processing/SADCP/OS75/LTA/$CRUISEid-OS75.LTA
# echo "  cat OS150 STA"
# cat $DEST/data-processing/SADCP/OS150/data/*.LTA > $DEST/data-processing/SADCP/OS150/LTA/$CRUISEid-OS150.LTA
# echo "  cat OS150 LTA"
# cat $DEST/data-processing/SADCP/OS150/data/*.STA > $DEST/data-processing/SADCP/OS150/STA/$CRUISEid-OS150.STA

# # copie TECHSAS ARCHIV_NETCDF vers data-raw
# echo "# copie TECHSAS ARCHIV_NETCDF vers data-raw"
# /bin/cp -rupv $SOURCE/DONNEES/$CRUISENvessel/ARCHIV_NETCDF/DONNEES/THS/*.ths $DEST/data-raw/TECHSAS/ARCHIV_NETCDF/THS
# /bin/cp -rupv $SOURCE/DONNEES/$CRUISENvessel/ARCHIV_NETCDF/DONNEES/NAV/*.nav $DEST/data-raw/TECHSAS/ARCHIV_NETCDF/NAV
# /bin/cp -rupv $SOURCE/DONNEES/$CRUISENvessel/ARCHIV_NETCDF/DONNEES/GPS/*.gps $DEST/data-raw/TECHSAS/ARCHIV_NETCDF/GPS
# /bin/cp -rupv $SOURCE/DONNEES/$CRUISENvessel/ARCHIV_NETCDF/DONNEES/FBOX/*.fbox $DEST/data-raw/TECHSAS/ARCHIV_NETCDF/FBOX
# /bin/cp -rupv $SOURCE/DONNEES/$CRUISENvessel/ARCHIV_NETCDF/DONNEES/MET/*.met $DEST/data-raw/TECHSAS/ARCHIV_NETCDF/MET

# # copie TECHSAS ARCHIV_NMEA vers data-raw et data-processing
# echo "# copie TECHSAS ARCHIV_NMEA vers data-raw et data-processing"
# /bin/cp -rupv $SOURCE/DONNEES/$CRUISENvessel/ARCHIV_NMEA/DONNEES/meteo/*.met $DEST/data-raw/TECHSAS/ARCHIV_NMEA/METEO
# /bin/cp -rupv $SOURCE/DONNEES/$CRUISENvessel/ARCHIV_NMEA/DONNEES/COLCOR/*.COLCOR $DEST/data-raw/TECHSAS/ARCHIV_NMEA/COLCOR

# copie données THERMO (TSG)
/bin/cp -rpv $SOURCE/THERMO/data/*.COLCOR $DEST/data-raw/THERMO
/bin/cp -rpv $SOURCE/THERMO/data/*.COLCOR $DEST/data-processing/THERMO/data

# /bin/cp -rupv $SOURCE/DONNEES/$CRUISENvessel/ARCHIV_NMEA/DONNEES/thsal/*.sal $DEST/data-raw/TECHSAS/ARCHIV_NMEA/SBE21
# /bin/cp -rupv $SOURCE/DONNEES/$CRUISENvessel/ARCHIV_NMEA/DONNEES/FYBOX/*.FYBOX $DEST/data-raw/TECHSAS/ARCHIV_NMEA/FYBOX
# /bin/cp -rupv $SOURCE/DONNEES/$CRUISENvessel/ARCHIV_NMEA/DONNEES/GILLA/*.gill $DEST/data-raw/TECHSAS/ARCHIV_NMEA/GILLA
# /bin/cp -rupv $SOURCE/DONNEES/$CRUISENvessel/ARCHIV_NMEA/DONNEES/.sonde18/*.snd $DEST/data-raw/TECHSAS/ARCHIV_NMEA/SONDE18

# copie CASINO vers data-raw et data-processing a partir de M:\RESILIENCE\DONNEES_BORD\CASINO
echo "# copie CASINO vers data-raw et data-processing"
/bin/cp -rv $SOURCE/CASINO/data/* $DEST/data-raw/CASINO
/bin/cp -rv $SOURCE/CASINO/data/*.csv $DEST/data-processing/CASINO/data

# copie XBT .edf vers data-raw et data-processing
echo "# copie XBT .edf de data-raw et data-processing"
/bin/cp -rpv $SOURCE/CELERITE/data/* $DEST/data-raw/CELERITE
/bin/cp -rpv $SOURCE/CELERITE/data/*.edf $DEST/data-processing/CELERITE/data
#for f in $DEST/data-processing/CELERITE/DATA/*\ *; do mv "$f" "${f// /_}"; done

echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
echo "Fin de synchro : `/bin/date +%d/%m/%Y_%H:%M:%S`"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
