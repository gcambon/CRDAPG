function [file] = prepladcp(p,files)
% function [file] = prepladcp(stn)
%
% prepare LADCP data for LADCP processing
%
% we need the raw LADCP data to be in the correct place and
% have the correct names.
%
% THIS FILE IS CRUISE SPECIFIC
%
% to create a file for your own cruise, modify this file
%
% you will just need to copy and possibly rename the files
% In case of old BB and NB systems you might need to append
% the raw data files.
%
% the convention for filenames is
%
% xxxDN000.000  and  xxxUP000.000  	with xxx the 3-digit station number
%
% they need to be copied into one directory per station
% data/raw_ladcp/xxx		with xxx the 3-digit station number

% G.Krahmann, IFM-GEOMAR, Aug 2005
% path pour windows
fprintf('    PREPLADCP  :');

% downward-looking L-ADCP file
if ~exist(files.ladcpdo,'file')
    disp(['> Cannot read LADCP DOWN data from ',files.ladcpdo]);
else
    disp('LADCP DOWN exist')
end

% upward-looking L-ADCP file
if ~exist(files.ladcpup,'file')
	disp(['                > Cannot read LADCP UP data from ',files.ladcpup]);
else
    disp('                LADCP UP exist')
end

% set file name
file = ['../data/raw_ladcp/',p.ladcp_station_name];

