function [values] = prepctdprof(p,files,values)
% function [values] = prepctdprof(stn,values)
%
% prepare CTD profile for LADCP
% we need an array 'ctdprof' containing the 3 columns
% pressure in dbar    in situ temperature in degrees C    salinity in psu
%
%
% THIS FILE IS CRUISE SPECIFIC
% 
% to create a file for your own cruise, modify this file
%
% the data should typically be a profile in 1dbar or 1m steps
% (a lower resolution of down to 10dbar or 10m might be sufficient)
% it will be used to calculate depth dependent sound speed corrections
%
% If such data is not available, a sound speed profile will be
% derived from the ADCP's temperature sensor, the integrated
% vertical velocity and a constant salinity.

% G.Krahmann, IFM-GEOMAR, Aug 2005

% if you do no have CTD profile data to be used in the 
% LADCP processing, uncomment the next two line, otherwise edit the following

%disp('YOU FIRST NEED TO EDIT THE FILE cruise_id/m/prepctdprof.m !')
%pause
%return

% first copy CTD profile to the raw CTD data directory
% data/raw_ctd
% this data could e.g. be coming from a mounted disk like in
% the example below
fprintf('    PREPCTDPROF  :');
fname = strcat(p.pathCTD, 'data/cnv/',p.id_mission,...
    p.ladcp_station_name, '.cnv');
if ~exist(fname,'file')
    disp(['> Cannot read CTD data from ',fname]);
    return
end

% load the data and convert to standard format
% in this example 
% we extract the PTS columns and get position and time data from the header
% you might have to convert depth to pressure in dbar
% and/or conductivity to salinity
[hdr,data] 	= read_sbe_cnv(fname);
ctdprof 	= [data.p,data.t_pri,data.s_pri];
pres	= data.p;
temp	= data.t_pri;
sal	    = data.s_pri;


% remove NaN values
ctdprof     = [pres temp sal];

% store data at the standard location
save6(['../data/ctdprof/ctdprof',p.ladcp_station_name],'ctdprof')

% save filename
file        = ['../data/ctdprof/ctdprof',p.ladcp_station_name];
