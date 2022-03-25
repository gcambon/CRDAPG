function [f] = misc_composefilenames(params,cfg)
% function [f] = misc_composefilenames(params,cfg);
%
% compose the output filenames, this can't be done earlier
%
% input  :      params          - parameter structure
%               cfg             - ctdseaprocessing parameter structure
%
% output :      f               - modified filename structure
%
% version 0.2  last change 08.11.2012

% GK, IFM-GEOMAR, Sep 2010

% moved stuff from default_params.m to here    GK, 08.11.2012  0.1-->0.2

% directory names
f.logs_dir        = '../logs';
f.plots_dir       = '../plots';
f.prof_dir        = '../profiles';
f.raw_dir         = '../data';
f.ctd_ts_dir      = '../data/ctdtime';
f.ctd_prof_dir    = '../data/ctdprof';
f.nav_dir         = '../data/nav';
f.sadcp_dir       = '../data/sadcp';

% file names
f.ladcpdo = [f.raw_dir '/' cfg.newfilename_LADCPM];
f.ladcpup = [f.raw_dir '/' cfg.newfilename_LADCPS];

f.nav     = [f.nav_dir,'/nav',params.ladcp_station_name,'.mat'];
f.ctdprof = [f.ctd_prof_dir,'/ctdprof',params.ladcp_station_name,'.mat'];
f.ctdtime = [f.ctd_ts_dir,'/ctdtime',params.ladcp_station_name,'.mat'];
f.sadcp   = [f.sadcp_dir,'/sadcp',params.ladcp_station_name,'.mat'];
f.sadcp2  = [f.sadcp_dir,'/sadcp2',params.ladcp_station_name,'.mat'];
f.dvl     = ['../data/dvl/dvl',params.ladcp_station_name,'.mat'];
f.buc     = ['../data/buc/buc',params.ladcp_station_name,'.mat'];

% file name for results (extensions will be added by software)
%  *.bot            bottom referenced ASCII data
%  *.lad            profile ASCII data
%  *.mat            MATLAB  format >> dr p ps f
%  *.cdf            NETCDF  (binary) LADCP data format 
%  *.log            ASCII log file of processing
%  *.txt            ASCII short log file
%  *.ps             post-script figure of result 


f.res   = [f.prof_dir,'/',params.name];
f.prof  = [f.prof_dir,'/',params.name];
f.plots = [f.plots_dir,'/',params.name];
f.log   = [f.logs_dir,'/',params.name];

% f.res   = [f.prof_dir,'/',params.name,'_',params.numtest];
% f.prof  = [f.prof_dir,'/',params.name,'_',params.numtest];
% f.plots = [f.plots_dir,'/',params.name,'_',params.numtest];
% f.log   = [f.logs_dir,'/',params.name,'_',params.numtest];

if length(f.log) > 1                    % open log file
  if exist([f.log,'.log'],'file')==2
    delete([f.log,'.log'])
  end
  diary([f.log,'.log'])
  diary on
end

