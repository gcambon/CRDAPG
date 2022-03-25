pwd
set "CRUISE=PIRATA-FR27"
set "DRIVE=M:\"
set "CONFIG=pirata-fr27.toml"
set "PREFIX=fr27"
M:\%CRUISE%\local\sbin\oceano2oceansites -c %DRIVE%%CRUISE%\data-processing\%CONFIG% -r %DRIVE%%CRUISE%\local\code_roscop.csv -e --files=%DRIVE%%CRUISE%\data-processing\CTD\data\cnv\%PREFIX%*.cnv --output=%DRIVE%%CRUISE%\data-processing\CTD
rem Uncomment to process all parameters 
rem M:\%CRUISE%\local\sbin\oceano2oceansites -c %DRIVE%%CRUISE%\data-processing\%CONFIG% -r %DRIVE%%CRUISE%\local\code_roscop.csv -e -a --files=%DRIVE%%CRUISE%\data-processing\CTD\data\cnv\%PREFIX%*.cnv --output=%DRIVE%%CRUISE%\data-processing\CTD
pause
