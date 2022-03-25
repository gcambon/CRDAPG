rem "script de copie des fichiers SBE35 et pressure stability vers le reseau pour FR32
set "CRUISE=PIRATA-FR32"
set "PREFIX=fr32"
set "PREFIXM=FR32"
echo "copy des fichiers vers -> M:\%CRUISE%\data-raw\CTD"
copy c:\SEASOFT\%CRUISE%\data\sbe35\%PREFIXM%%1.asc M:\%CRUISE%\data-raw\CTD\sbe35
copy "c:\SEASOFT\%CRUISE%\data\Pressure Stability\%PREFIXM%%1*.*" "M:\%CRUISE%\data-raw\CTD\Pressure Stability"
echo "copy des fichiers vers -> M:\%CRUISE%\data-processing\CTD"
copy c:\SEASOFT\%CRUISE%\data\sbe35\%PREFIXM%%1.asc M:\%CRUISE%\data-processing\CTD\data\sbe35
copy "c:\SEASOFT\%CRUISE%\data\Pressure Stability\%PREFIXM%%1.asc" "M:\%CRUISE%\data-processing\CTD\data\Pressure Stability"
pause
