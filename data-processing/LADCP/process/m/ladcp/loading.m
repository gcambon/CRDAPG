function [data,messages] = loading(files,data,messages,params)
% function [data,messages] = loading(files,data,messages,params)
%
% loads LADCP and ancillary data files prepared by routines
% prepctdtime.m prepctdprof.m prepnav.m prepsadcp.m
%
% input  :	files		- LADCP file name structure
%		data		- LADCP data structure
%		messages	- LADCP processing message structure
%		params	- LADCP processing parameter structure
%
% output :	data		- LADCP data structure
%		messages	- modified LADCP processing message structure
%
% version 0.2	last change 19.09.2007

% G.Krahmann, LDEO Nov 2004

% added switch to turn off SADCP usage		GK, Sep 2007 	0.1-->0.2


%
% general function info
%
disp(' ')
disp('LOADING:  load the prepared MAT files')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load position-time (navigation) file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data = navload(files,data);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load CTD-time file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data = ctdtimeload(files,data);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load CTD-pressure file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data = ctdprofload(files,data);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load SADCP file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data = sadcpload(files,data,params);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load second SADCP file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data = sadcpload2(files,data,params);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load DVL file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data = dvlload(files,data,params);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load BUC file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data = bucload(files,data,params);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ndata = navload(files,ndata)
%
% load navigational data prepared by prepnav.m
%
disp(['    NAV    : loading NAV time series ',files.nav])
if exist(files.nav,'file')==0
  ndata.nav_time = [];
  ndata.nav_data = [];
  disp(['>   Can not find ',files.nav])
else
  load(files.nav);
  ndata.nav_time = timnav;
  ndata.nav_data = data;
  disp(['      Number of NAV lines     : ',int2str(length(timnav))])
  disp(['      Data rate               : ',...
	num2str(median(diff(timnav))*86400),' seconds'])
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ndata = ctdtimeload(files,ndata)
%
% load CTD-time data prepared by prepctdtime.m
%
disp(['    CTDTIME: loading CTD-time series ',files.ctdtime])
if exist(files.ctdtime,'file')==0
  ndata.ctdtime_time = [];
  ndata.ctdtime_data = [];
  disp(['>   Can not find ',files.ctdtime])
else
  load(files.ctdtime);
  ndata.ctdtime_time = timctd;
  ndata.ctdtime_data = data;
  disp(['      Number of CTD-time lines: ',int2str(length(timctd))])
  disp(['      Data rate               : ',...
	num2str(median(diff(timctd))*24*3600),...
	' seconds'])
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ndata = ctdprofload(files,ndata)
%
% load CTD-pressure data prepared by prepctdprof.m
%
disp(['    CTD    : loading CTD profile data ',files.ctdprof])
if exist(files.ctdprof,'file')==0
  ndata.ctdprof = [];
  disp(['>   Can not find ',files.ctdprof])
else
  load(files.ctdprof);
  ndata.ctdprof = ctdprof;
  disp([  '      Number of CTD-prof lines: ',int2str(length(ctdprof))])
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ndata = sadcpload(files,ndata,params)
%
% load SADCP data prepared by prepsadcp.m
%
disp(['    SADCP  : loading SADCP profile data ',files.sadcp])
if exist(files.sadcp,'file')==0
  ndata.tim_sadcp = [];
  ndata.lat_sadcp = [];
  ndata.lon_sadcp = [];
  ndata.u_sadcp   = [];
  ndata.v_sadcp   = [];
  ndata.z_sadcp   = [];
  disp(['>   Can not find ',files.sadcp])
elseif params.use_sadcp==0
  ndata.tim_sadcp = [];
  ndata.lat_sadcp = [];
  ndata.lon_sadcp = [];
  ndata.u_sadcp   = [];
  ndata.v_sadcp   = [];
  ndata.z_sadcp   = [];
  disp(['>   SADCP data exists but is turned off via params.use_sadcp'])
else
  load(files.sadcp);
  ndata.tim_sadcp = tim_sadcp;
  ndata.lat_sadcp = lat_sadcp;
  ndata.lon_sadcp = lon_sadcp;
  ndata.u_sadcp   = u_sadcp;
  ndata.v_sadcp   = v_sadcp;
  ndata.z_sadcp   = z_sadcp;
  disp(['      Number of SADCP profiles: ',int2str(length(tim_sadcp))])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ndata = sadcpload2(files,ndata,params)
%
% load SADCP data prepared by prepsadcp.m
%
disp(['    2nd SADCP  : loading second SADCP profile data ',files.sadcp2])
if exist(files.sadcp2,'file')==0
  ndata.tim_sadcp2 = [];
  ndata.lat_sadcp2 = [];
  ndata.lon_sadcp2 = [];
  ndata.u_sadcp2   = [];
  ndata.v_sadcp2   = [];
  ndata.z_sadcp2   = [];
  disp(['>   Can not find ',files.sadcp2])
elseif params.use_sadcp2==0
  ndata.tim_sadcp2 = [];
  ndata.lat_sadcp2 = [];
  ndata.lon_sadcp2 = [];
  ndata.u_sadcp2   = [];
  ndata.v_sadcp2   = [];
  ndata.z_sadcp2   = [];
  disp(['>   2nd SADCP data exists but is turned off via params.use_sadcp'])
else
  load(files.sadcp2);
  ndata.tim_sadcp2 = tim_sadcp2;
  ndata.lat_sadcp2 = lat_sadcp2;
  ndata.lon_sadcp2 = lon_sadcp2;
  ndata.u_sadcp2   = u_sadcp2;
  ndata.v_sadcp2   = v_sadcp2;
  ndata.z_sadcp2   = z_sadcp2;
  disp(['      Number of second SADCP profiles: ',int2str(length(tim_sadcp2))])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ndata = dvlload(files,ndata,params)
%
% load SADCP data prepared by prepdvl.m
%
disp(['    DVL  : loading DVL profile data ',files.dvl])
if exist(files.dvl,'file')==0
  ndata.tim_dvl = [];
  ndata.lat_dvl = [];
  ndata.lon_dvl = [];
  ndata.u_dvl   = [];
  ndata.v_dvl   = [];
  ndata.z_dvl   = [];
  disp(['>   Can not find ',files.dvl])
elseif params.use_dvl==0
  ndata.tim_dvl = [];
  ndata.lat_dvl = [];
  ndata.lon_dvl = [];
  ndata.u_dvl   = [];
  ndata.v_dvl   = [];
  ndata.z_dvl   = [];
  disp(['>   DVL data exists but is turned off via params.use_dvl'])
else
  load(files.dvl);
  ndata.tim_dvl = tim_dvl;
  ndata.lat_dvl = lat_dvl;
  ndata.lon_dvl = lon_dvl;
  ndata.u_dvl   = u_dvl;
  ndata.v_dvl   = v_dvl;
  ndata.z_dvl   = z_dvl;
  disp(['      Number of DVL profiles: ',int2str(length(tim_dvl))])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ndata = bucload(files,ndata,params)
%
% load SADCP data prepared by prepdvl.m
%
disp(['    BUC  : loading BUC profile data ',files.buc])
if exist(files.buc,'file')==0
  ndata.tim_buc     = [];
  ndata.lat_buc     = [];
  ndata.lon_buc     = [];
  ndata.u_buc       = [];
  ndata.v_buc       = [];
  ndata.speed_buc   = [];
  ndata.dist_buc    = [];
  ndata.heading_buc = [];
  disp(['>   Can not find ',files.buc])
elseif params.use_buc==0
  ndata.tim_buc     = [];
  ndata.lat_buc     = [];
  ndata.lon_buc     = [];
  ndata.u_buc       = [];
  ndata.v_buc       = [];
  ndata.speed_buc   = [];
  ndata.dist_buc    = [];
  ndata.heading_buc = [];
  disp(['>   BUC data exists but is turned off via params.use_buc'])
else
  load(files.buc);
  ndata.tim_buc     = time_buc;
  ndata.lat_buc     = lat_buc;
  ndata.lon_buc     = lon_buc;
  ndata.u_buc       = u_buc;
  ndata.v_buc       = v_buc;
  ndata.speed_buc   = speed_buc;
  ndata.dist_buc    = dist_buc;
  ndata.heading_buc = heading_buc;
  disp(['      Number of BUC profiles: ',int2str(length(time_buc))])
end