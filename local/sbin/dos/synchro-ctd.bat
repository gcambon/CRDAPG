rem "script to copy CTD/LADCP raw files over the network data-raw and data-processing"

rem echo "copy acquisition files to -> %DRIVE%\%CRUISE%\data-raw\CTD"
copy c:\SEASOFT\%CRUISE%\data\sbe35\%PREFIXM%%1.asc %DRIVE%\%CRUISE%\data-raw\CTD\sbe35
copy c:\SEASOFT\%CRUISE%\data\%PREFIX%%1.* %DRIVE%\%CRUISE%\data-raw\CTD
rem copy "c:\SEASOFT\%CRUISE%\data\Pressure Stability\%PREFIXM%%1*.*" "%DRIVE%\%CRUISE%\data-raw\CTD\Pressure Stability"
rem echo "copy acquisition files -> %DRIVE%\%CRUISE%\data-processing\CTD"
copy c:\SEASOFT\%CRUISE%\data\sbe35\%PREFIXM%%1.asc %DRIVE%\%CRUISE%\data-processing\CTD\data\sbe35
copy c:\SEASOFT\%CRUISE%\data\%PREFIX%%1.* %DRIVE%\%CRUISE%\data-processing\CTD\data\raw
rem copy "c:\SEASOFT\%CRUISE%\data\Pressure Stability\%PREFIXM%%1.asc" "%DRIVE%\%CRUISE%\data-processing\CTD\data\Pressure Stability"
copy c:\LADCP\%CRUISE%\data\%PREFIX%M%1.* %DRIVE%\%CRUISE%\data-raw\LADCP
copy c:\LADCP\%CRUISE%\data\%PREFIX%S%1.* %DRIVE%\%CRUISE%\data-raw\LADCP
copy c:\LADCP\%CRUISE%\data\%PREFIX%M%1.* %DRIVE%\%CRUISE%\data-processing\LADCP\data
copy c:\LADCP\%CRUISE%\data\%PREFIX%S%1.* %DRIVE%\%CRUISE%\data-processing\LADCP\data
pause
