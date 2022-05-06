#!/bin/bash
#
# Mission RESILIENCE N/O Marion Dufresne fevrier 2022 P.Rousselot (J. Grelet)
# script de synchronisation des donnees navire sur mission data-raw et data-processing

# /m -> /mnt/campagnes 
# /q -> /mnt/q
# lancer:
# > sudo bash /mnt/campagnes/RESILIENCE/local/sbin/synchro.sh

# repertoires source
export SOURCE=/mnt/missioncourante
export EQUIP=/mnt/missioncourante/EQUIPEMENTS
export CRUISE=$1
export DRIVE=$2
##export CRUISE=RESILIENCE
##export DRIVE=/mnt/science
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
# copie SADCP vers data-raw et data-processing
echo "# copie SADCP vers data-raw et data-processing"
rsync -u --progress $EQUIP/OS75/DONNEES/*         $DEST/data-raw/SADCP/OS75
rsync -u --progress $EQUIP/OS75/DONNEES/*.[L-S]TA $DEST/data-processing/SADCP/OS75/data
# OS150
rsync -u --progress $EQUIP/OS150/DONNEES/*         $DEST/data-raw/SADCP/OS150
rsync -u --progress $EQUIP/OS150/DONNEES/*.[L-S]TA $DEST/data-processing/SADCP/OS150/data

# # LOCH RDI DVL600
# /bin/cp -rupv $SONDEURS/$CRUISENvessel/LOCH/ANNEXES/* $DEST/data-raw/SADCP/DVL600/ANNEXES
# /bin/cp -rupv $SONDEURS/$CRUISENvessel/LOCH/DONNEES/* $DEST/data-raw/SADCP/DVL600
# /bin/cp -rupv $SONDEURS/$CRUISENvessel/LOCH/DONNEES/*.[L-S]TA $DEST/data-processing/SADCP/DVL600/data

echo "# cat SADCP files"
echo "  cat OS75 STA"
cat $DEST/data-processing/SADCP/OS75/data/*.STA >  $DEST/data-processing/SADCP/OS75/STA/$CRUISEid-OS75.STA
echo "  cat OS75 LTA"
cat $DEST/data-processing/SADCP/OS75/data/*.LTA >  $DEST/data-processing/SADCP/OS75/LTA/$CRUISEid-OS75.LTA
echo "  cat OS150 STA"
cat $DEST/data-processing/SADCP/OS150/data/*.LTA > $DEST/data-processing/SADCP/OS150/LTA/$CRUISEid-OS150.LTA
echo "  cat OS150 LTA"
cat $DEST/data-processing/SADCP/OS150/data/*.STA > $DEST/data-processing/SADCP/OS150/STA/$CRUISEid-OS150.STA

# copie TECHSAS ARCHIV_NETCDF vers data-raw
echo "# copie TECHSAS ARCHIV_NETCDF vers data-raw"
rsync -u --progress $SOURCE/ARCHIV_NETCDF/DONNEES/NetCDF/THS/*.ths   $DEST/data-raw/TECHSAS/ARCHIV_NETCDF/THS
rsync -u --progress $SOURCE/ARCHIV_NETCDF/DONNEES/NetCDF/NAV/*.nav   $DEST/data-raw/TECHSAS/ARCHIV_NETCDF/NAV
rsync -u --progress $SOURCE/ARCHIV_NETCDF/DONNEES/NetCDF/GPS/*.gps   $DEST/data-raw/TECHSAS/ARCHIV_NETCDF/GPS
rsync -u --progress $SOURCE/ARCHIV_NETCDF/DONNEES/NetCDF/FBOX/*.fbox $DEST/data-raw/TECHSAS/ARCHIV_NETCDF/FBOX
rsync -u --progress $SOURCE/ARCHIV_NETCDF/DONNEES/NetCDF/MET/*.met   $DEST/data-raw/TECHSAS/ARCHIV_NETCDF/MET

# copie TECHSAS ARCHIV_NMEA vers data-raw et data-processing
echo "# copie TECHSAS ARCHIV_NMEA vers data-raw TECHSAS/ARCHIV_NMEA/"
rsync -u --progress $SOURCE/ARCHIV_NMEA/ANEMO/*.txt       $DEST/data-raw/TECHSAS/ARCHIV_NMEA/METEO
rsync -u --progress $SOURCE/ARCHIV_NMEA/COLCOR/*.COLCOR*  $DEST/data-raw/TECHSAS/ARCHIV_NMEA/COLCOR
rsync -u --progress $SOURCE/ARCHIV_NMEA/SBE21/*.txt       $DEST/data-raw/TECHSAS/ARCHIV_NMEA/SBE21
rsync -u --progress $SOURCE/ARCHIV_NMEA/FYBOX/*.txt       $DEST/data-raw/TECHSAS/ARCHIV_NMEA/FYBOX
#rsync -u --progress ARCHIV_NMEA/DONNEES/GILLA/*.gill    $DEST/data-raw/TECHSAS/ARCHIV_NMEA/GILLA
rsync -u --progress $SOURCE/ARCHIV_NMEA/EK018/*.txt       $DEST/data-raw/TECHSAS/ARCHIV_NMEA/SONDE18

# === copie données THERMO vers data-raw et data-processing
rsync -u --progress $SOURCE/ARCHIV_NMEA/COLCOR/*.COLCOR $DEST/data-raw/THERMO
rsync -u --progress $SOURCE/ARCHIV_NMEA/COLCOR/*.COLCOR $DEST/data-processing/THERMO/data

# copie CASINO vers data-raw et data-processing
echo "# copie CASINO vers data-raw et data-processing"
rsync -u --progress $SOURCE/CASINO/BASE_LOCALE/*     $DEST/data-raw/CASINO
rsync -u --progress $SOURCE/CASINO/BASE_LOCALE/*.csv $DEST/data-processing/CASINO/data

# copie XBT .edf vers data-raw et data-processing
echo "# copie XBT .edf de data-raw et data-processing"
rsync -u --progress $SOURCE/CELERITE/*             $DEST/data-raw/CELERITE
rsync -u --progress $SOURCE/CELERITE/DONNEES/*.edf $DEST/data-processing/CELERITE/data
#for f in $DEST/data-processing/CELERITE/DATA/*\ *; do mv "$f" "${f// /_}"; done

echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
echo "Fin de synchro : `/bin/date +%d/%m/%Y_%H:%M:%S`"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
