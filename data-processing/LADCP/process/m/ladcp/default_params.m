% LADCP processing software
%
% set default values for parameter in LADCP processing
% 
%  INPUT is provided by three structures.
%  some of this may get changed by the software
%
% structure f.??? contains file names
% structure p.??? contains parameter relevant to reading and preparing
%             the data
% structure ps.??? contains parameter for the solution
%
% version 0.5  last change 14.02.2013

% changed handling of cruise_id              GK, 20.05.2011  0.1-->0.2
% new parameter to fully remove bins         GK, 29.08.2011  0.2-->0.3
% new parameter to force resampling          GK, 07.03.2012  0.3-->0.4
% new parameter to handle wrong clocks       GK, 14.02.2013  0.4-->0.5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% General paramaters
params.software = 'GEOMAR LADCP software: Version 10.16: 2013-02-14';

% unix computers know this
params.whoami   = whoami;

% store station number and name (in proper format)
params.ladcp_station_name = stn;
params.ladcp_station      = str2num(stn);

% extract cruise id from upper directory name
pd          = pwd;
params.name = 'unknown_cruise_id';
if exist('logs')==7
  if ispc
    ind = findstr(pd,'\');
  else
    ind = findstr(pd,'/');
  end
  if ~isempty(ind)
    params.name = pd(ind(end)+1:end);
  else
    params.name = pd;
  end
  params.name   = [params.name,'_',params.ladcp_station_name];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Default parameters p
%--------------------------------------------------------------
% Parameter for loading and primary error check  p.* structure
%--------------------------------------------------------------
%% POSITION PARAMETERS
% preset start and end time vectors
params.time_start             = [];
params.time_end               = [];

% manually set POSITION of the start and end point
% [degree lat, minute lat, degree lon, minute lon]
%  i.e. [-59 -30.5697 -44 -22.4986]
params.pose                   = [0 0 0 0]*nan;
params.poss                   = [0 0 0 0]*nan;
params.position_fixed         = 0;
params.lat_for_calc           = 0;
params.lon_for_calc           = 0;

% navigation error in m
%
% This one is later used to determine the weight of the ship
% movement constraint. It should be set to something like the
% uncertainty of the position of the CTD when it is coming on 
% deck. I.e. the GPS error plus something accounting for the
% position difference between GPS antenna and CTD (remember
% the ship can rotate !).
% 30 m is a reasonable number.
params.nav_error              = 30;

%% SUPER ENSEMBLES 
% are calculated in prepinv.m to reduce the number of raw profiles
% The ides is to obtain one average profile for each vertical dz=const
% that the CTD traveled through. As a result a constant number of super
% ensembles are obtained for the up and down cast.
% but a fixed number of ensembles can also be averaged
% p.avdz sets the depth interval between adjacent super-ensembles
% default one bin length since the bin length is profile dependent 
% we can not set it here
% if avdz is negative, -avdz bin lengths will be used for avdz
% if avdz is positive, avdz will be used as is
% the calculation takes place in  calc_ens_av.m
% p.avens will take precedence over p.avdz
params.avdz                   = -1;

% p.avens overrides p.avdz and sets a fixed number of ensembles to average
% default NAN means that it is not used
params.avens                  = NaN;

%% BOTTOM TRACK
% 	The are several options to get bottom track data
% 
% mode = 1 :   use only RDI bottom track
%        2 :   use only own bottom track
%        3 :   use RDI, if existent, own else (default)
%        0 :   use not bottom track at all
%
% btrk_mode is the one you set to be used, btrk_used is the 
% the routine has used. They do not need to agree since the
% software can override your command, e.g. in case some
% necessary data is missing or all BTRK are bad.
params.btrk_mode              = 3;
params.btrk_used              = 0;	

% p.btrk_ts is in dB to detect bottom above bin1 level (for own btm track)
%
% The following parameter (bottom-tracking target strength)
% is quite iffy. Setting it to too small a value (e.g. 10, the old default)
% makes instrument interference appear as a false bottom, which can
% be a problem. For example, on CLIVAR P02 station 32 there was a
% long stop 16m above the sea bed, which is too close for bottom
% tracking.  True bottom detection is only possible during the approach
% and the beginning of the upcast. These two short times are swamped
% out by the interference-related false bottom detections. On the other
% hand, when this value is set to too large a value, true seabed returns
% are rejected. It would be fairly easy to set the correct value in
% terms of instrument-returned target strength by plotting the target
% strength with imagesc(d.wts). However, the values of this parameter
% are not instrument-returned target strengths but db. The current value
% is valid for the combo of downlooking BB150 / uplooking WH300 used on
% the CLIVAR P02 cruise. It was derived by trial and error, involving
% stations 2 and 32.
params.btrk_ts                = 30;

% p.btrk_below gives binoffset used below target strength maximum
% to make bottom track velocity
params.btrk_below             = 0.5;

% p.btrk_range gives minumum / maximum distance for bottom track
% will be set to 2 / 10 binlength later
%params.btrk_range            = [50 300];

% p.btrk_wstd gives maximum accepted wstd for super ensemble averages
% this one is usually calculated from the BTRK data but you can
% override it
%p.btrk_wstd                  = 0.1;

% maximum allowed difference between reference layer W and W bottom track
params.btrk_wlim              = 0.05;

% force to recalculate bottom distance using target strength
% this is turned off (0) by default and is being automatically
% turned on (1), if the routine recognizes a large number of
% bad (equal 0) RDI distances to the bottom
params.bottomdist             = 0;

%% SURFACE REFLECTION
% p.surfdist = 1 use surface reflections of up looking ADCP to get start
% depth
params.surfdist               = 1;

%% MAGNETIC PARAMETERS
% MAGNETIC deviation in degree
params.magdev                 = 0;

% COMPASS manipulation
% experts only 
% fix_compass:1 means hdg_offset gets added
% fix_compass:2 means up looker gets down compass + hdg_offset
% fix_compass:3 means down looker gets up compass + hdg_offset
params.fix_compass            = 0;

% In case the two instruments are running not synchronous, one
% is resampled onto the other. This is done by simply taking
% one instrument as the reference (default the downlooker) and
% each of its ensembles pick the closest in time of the other
% instrument. Depending on the ping rates and which instrument
% is pinging faster, this will result in whole ensembles being
% dropped or used multiple times.
% params.up2down==0 will not resample, unless different ping rates are detected
% params.up2down==1 will resample the uplooker onto the downlooker
% params.up2down==2 will resample the downlooker onto the uplooker
params.up2down                = 0;

% give compass offset in addition to declination (1) for down (2) for up
%p.hdg_offset                 = [0 0];

% COMPASS: 
% how to best adjust compass to best match 
% if 1 rotate up-looking and down-looking instrument to mean heading
%    2 rotate up-looking and down-looking velocities to match up velocities
%        (not really recommended and very likey buggy !!!)
%    3 rotate up-looking velocities to down heading
%        (use if you suspect that the up heading is bad)
%    4 rotate down-looking velocities to up heading
%        (use if you suspect that the down heading is bad)
params.rotup2down             = 1;

% Offset correction
% if 1 remove velocity offset between up and down looking ADCP
% this will correct errors due to tilt biases etc.
params.offsetup2down          = 1;

%% TIME/DEPTH PARAMETERS
% restrict time range to profile and disregard data close to surface
% p.cut = 0 dont restrict
% p.cut > 0 restrict time to adcp depth below a depth of p.cut
params.cut                    = 10;

% DEPTH of the start, bottom and end of the profile positive downwards
params.zpar                   = [0 NaN 0];

% maximum number of bins to be used 0 : all will get used 
params.maxbinrange            = 0;

% set ctdmaxlag.=100 to the maximum pings that the ADCP data can be shifted to 
% best match W calculated from CTD pressure time series (loadctd)
% If you have good times set it to 10... if your time base is questionable
% you can set it 100 or more
params.ctdmaxlag              = 10;
params.ctdmaxlagnp            = 10;

% set forced_adcp_ctd_lag in case the built-in routine does not properly 
% recognize the lag usually this is not set at all 
% params.forced_adcp_ctd_lag;

%% 1200kHz
% 1200kHz WH data is too high resolution to be merged with other data
% it thus needs to be averaged before being used
% this gives the number of values to be averaged
params.nav_1200               = 4;

% a 1200kHz measures very close to the rosette
% high error velocities result when measured in the eddy tail of the rosette
% this parameter sets the threshold of values to be discarded
params.error_limit_1200       = 20;	% not used GK
params.extra_blank_1200       = 5;    % extra blank in meters

%% CLEAN DATA
%OUTLIER detection is called twice once to clean the raw data
%	and a second time to clean the super ensembles
%        [n1 n2 n3 ...] the length gives the number of scans and
%	each value the maximum allowed departure from the mean in std
%	applied for the u,v,w fields for each bin over blocks 
%   of p.outlier_n profiles
% 2: very strong  3: medium  4:only largest outliers
params.outlier                = [4, 3];

% default for p.outlier_n is number of profiles in 5 minutes
%p.outlier_n                  = 100;

% minimum std for horizontal velocities of super ensemble
%psuperens_std_min            = 0.01;

%SPIKES
% 	maximum value for abs(V-error) velocity
params.elim                   = 0.5;
% 	maximum value for horizontal velocity 
params.vlim                   = 2.5;
% 	minimum value for %-good
params.pglim                  = 0;
%	maximum value for W difference between the mean W and actual
%        W(z) for each profile. 
params.wlim                   = 0.20;

%% TILT
%TILT  flag data with large tilt or tilt differences as bad
% [22  (max tilt allowed) 
% 4 (maximum tilt difference between pings allowed)]
% WH systems have reported decent profiles with up to 35 deg tilt ...
params.tiltmax                = [20 4];

% TILT  reduce weight for large tilts
% calculated after an obscure formula in prepinv.m GK
% have a look at
% plot([0:0.1:30],1.-tanh([0:0.1:30]/params.tilt_weight)/2)
% to see the effect
% 10 means a weight of 1.0 for tilts of  0 deg
%          a weight of 0.6 for tilts of 10 deg
%          a weight of 0.5 for tilts of 30 deg
% a tilt_weight of 20 appears to be more gentle, GK
params.tilt_weight            = 10;

% apply tilt correction
% tiltcor(1)=down-pitch bias
% tiltcor(2)=down-rol bias
% tiltcor(3)=up-pitch bias
% tiltcor(4)=up-rol bias
params.tiltcor                = 0;

%% TIME & LAG
% fix TIME of the ADCP in days
% positive numbers shift the ADCP's time to a later time
% (i.e. timoff is added to the julian time of the ADCP)
% Please note that here is only one offset possible.
% This is the offset of the MASTER system.
% Should the LADCP slave system have a different offset, it
% will be handled by the data shifting of the slave.
params.timoff                 = 0;

% fix time of uplooking ADCP relative to downlooking ADCP
% e.g. when the clocks were never properly set
% Usually that is taken care of by the automatic shifting.
% But this will fail when the uplooking system apparently start
% before the downlooking one, but in reality starts later.
%
% In that case you can shift the uplooking data to later
% times by giving a positive number. Units are days.
% There will be a paused control plot to compare the vertical
% velicities.
params.timoff_uplooker        = 0;

% by up to how many ensembles shall the slave be shifted 
% against the master so that the vertical velocities match
% usually 20 is enough. But if the times of master and
% slave were not properly set a much larger number might
% be necessary
params.maxlag                 = 20;

% there is still an old slower up/down lag routine implemented
% it is turnned off by default and the newer one is used
% it will automatically turn on, if the bestlag found has a correlation
% of less than 0.9
params.bestlag_testing_on     = 0;

%% REFERENCE LAYER & PRESSURE SENSOR
% Give bin number for the best W to compute depth of the ADCP
% default uses bin 2-3 but be careful when up/down instruments
% are used. The good bins are in the middle! 
params.trusted_i              = [2:5];

% SET ambiguity velocity used [m/s]
% not used for anything, but stored in the archival data !? GK
params.ambiguity              = 2.5;

% Give single ping accuracy;
% another strange one, set to NaN, multiplies something and
% that's it  GK
params.single_ping_accuracy   = NaN;

% clear LADCPs pressure sensor
% sometimes has strange data and w integration might be preferred
% 1 clears the pressure records
params.clear_ladcp_pressure   = 0;
params.weight_ladcp_pressure  = 0.1;

%% SAVE PARAMETERS
% save individual target strength 
params.ts_save                = [1 2 3 4];

% save individual correlation p.cm_save=[1 2 3 4]
params.cm_save                = 0;

% save individual percent good pings p.pg_save=[1 2 3 4]
params.pg_save                = 0;

% Write matlab file
params.savemat                = 1;

% Write netcdf file
params.savecdf                = 1;

% Save Plots 
% Save figure numbers to ps file
%    1 : Summary Plot
%    2 : Engineering Data
%    3 : Data Quality
%    4 : Depth
%    5 : Heading Corrections 
%    6 : Up/Down Differences
%    7 : CTD Position
%    8 : Shear
%    9 : SADCP U, V 
%   10 : DVL U, V 
%   11 : U, V Offsets, Tilt Error
%   12 : Processing Warnings
%   13 : Inversion Constraints
%   14 : Bottom Track detail
%   15 : Target Strength
%   16 : Correlation
%   17 : Weights
params.saveplot               = 1:17;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Default parameters ps
%--------------------------------------------------------------
% Parameter for inversion   ps.* structure
%--------------------------------------------------------------

%% SHEAR
% Process data using shear based method
% compute shear based solution
% ps.shear=2  ; use super ensemble
% ps.shear=1  ; use raw data
ps.shear                      = 1;

% average over data within how many standard deviations
ps.shear_stdf                 = 2;

% the minimum weight a bin must have to be accepted for shear
ps.shear_weightmin            = 0.1;

% Request that shears are small  (experts only)
%ps.smallfac                  = [1,0];

%% SADCP constraint
% use SADCP data (1) or not (0) default is to use the data. 
% This is just a simple switch to simplify testing of results
params.use_sadcp              = 0;
params.use_sadcp2             = 0;

% Weight for SADCP data
% ps.sadcpfac=1 about equal weight for SADCP profile
ps.sadcpfac                   = 0;
ps.sadcpfac2                  = 0;

% The following parameter (slack time for including SADCP data outside
% LADCP-cast time interval) is by default set to 5 minutes. On CLIVAR_P02
% this is too much, since we ran an efficient operation. Sometimes, the
% ship was getting underway less than 5 minutes after the end of the cast.
% This led to SADCP data outliers, which increases the standard deviation,
% which makes the inversion reject all SADCP data (low weight).
params.sadcp_dtok             = 0;            % no time slack for SADCP near ends of stn
params.sadcp2_dtok            = 0;            % no time slack for SADCP near ends of stn

%% DVL constraint
% use DVL data (1) or not (0) default is to use the data. 
% This is just a simple switch to simplify testing of results
params.use_dvl                = 1;

% Weight for DVL data
% ps.dvlfac=1 about equal weight for DVL profile
ps.dvlfac                   = 0;

% The following parameter (slack time for including DVL data outside
% LADCP-cast time interval) is by default set to 5 minutes. On CLIVAR_P02
% this is too much, since we ran an efficient operation. Sometimes, the
% ship was getting underway less than 5 minutes after the end of the cast.
% This led to SADCP data outliers, which increases the standard deviation,
% which makes the inversion reject all DVL data (low weight).
params.dvl_dtok             = 0;            % no time slack for DVL near ends of stn

%% BUC constraint
% use BUC data (1) or not (0) default is to use the data. 
% This is just a simple switch to simplify testing of results
params.use_buc              = 0;

% Weight for BUC data
% ps.bucfac=1 about equal weight for BUC profile
ps.bucfac                   = 0;

%% BOTTOM TRACK constraint
% Weight for the bottom track constraint
ps.botfac                     = 0; 

% weight bottom track data with distance of bottom
% use Gaussian with offset (btrk_weight_nblen(1) * bin)
% and width (btrk_weight_nblen(2) * bin) 
% one might set this to [15 5] to reduce the weight of close by bottom track data
ps.btrk_weight_nblen          = [0 0];

%% BAROTROPIC constraint
% Weight for the barotropic constraint
ps.barofac                    = 1;

%% UP/DOWN
% Process up and down cast seperately
ps.down_up                    = 1;

% restrict inversion to one instrument only 1: up+dn, 2:dn only  3:up only
ps.up_dn_looker               = 1;

% multiply the weight of up and/or down looker by a factor
params.down_up_weight_factors = [1,1];

%% RESOLUTION
% Smoothing of the final profile
ps.smoofac                    = 0;

% decide how to weigh data 
% 1 : use super ensemble std 
% 0 : use correlation based field
ps.std_weight                 = 1;

% Depth resolution for final profile default one bin length
%ps.dz                        = medianan(abs(diff(di.izm(:,1))));

% super ensemble velocity error
% try to use the scatter in W to get an idea of the "noise"
% in the velocity measurement
% This is a bit of code used in GETINV.m
% nmax=min(length(di.izd),7);
% sw=nstd(di.rw(di.izd(1:nmax),:)); ii=find(sw>0);
% sw=medianan(sw(ii))/tan(p.Beam_angle*pi/180);
% ps=setdefv(ps,'velerr',max([sw,0.02]));
%ps.velerr                    = 0.02;

% How to solve the inverse
%     ps.solve = 0  Cholesky transform
%              = 1  Moore Penrose Inverse give error for solution
ps.solve                      = 1; 

% Threshold for minimum weight, data with smaller weights
% will be ignored
ps.weightmin                  = 0.05;

% Change the weights by 
%	weight=weight^ps.weightpower 
ps.weightpower                = 1; 

% Remove 1% of outliers (values in a superensemble deviating most from 
% the inversion result) after solving the inversion
% ps.outlier defines how many times 1% is removed and the
% inversion is recalculated.
ps.outlier                    = 1; 

% Weight for the cable drag constraint only for experts
ps.dragfac                    = 0; 
ps.drag_tilt_vel              = 0.5;

% average ctdvel back in time to take the inertia of wire into account
% smooth over max of 20 minutes for depth ~ 2000m
ps.drag_lag_tim               = 20;
ps.drag_lag_depth             = 2000;

% set the ranges for the main velocity plot
% [nan,nan,nan,0] will use standard variable axis ranges
% with this setting you can set it to something fixed for easier 
% comparison units are [cm/s cm/s m m] (depth is positive)
params.plot_range             = [nan,nan,0,nan];

% set the maximum distance for the bottom track velocity plot
params.btrk_plot_range        = 400;

%% PARAMETERS FOR EDIT_DATA
% Set list of bins to always remove from data.
params.edit_mask_dn_bins             = [];
params.edit_mask_up_bins             = [];

% set list of bins to fully remove from data this will be done 
% already at the loading stage and should very rarely be necessary
params.edit_hardremove_mask_dn_bins  = [];
params.edit_hardremove_mask_up_bins  = [];

% Set to 1 to remove side-lobe contaminated data near seabed and
% surface.
params.edit_sidelobes                = 1;

% Set to finite value to implement time-domain spike filter on the data; 
% this removes interference from other acoustic instruments but,
% more importantly, can get rid of PPI when staggered pings are used.
% Spike filtering is done using 2nd-difference
% peak detection in time. This parameter gives the maximum target-strength
% 2nd derivative that's allowed. Set to larger values to weaken the 
% filtering. (Check figure 14 to see if filter is too strong or too weak.)
% has been normalized to handle different instruments 
% old values from pre-10 versions will not work !!!  GK
params.edit_spike_filter_max_curv    = 0.1;

% Set to 1 to remove data contaminated by previous-ping interference.
% NB: using the spike filter seems to work more robustly, as long
% as staggered pings are used.
params.edit_PPI                      = 0;

% PPI layer thickness in meters; the value is taken directly from Eric
% Firing's default (2*clip_margin = 180m).
params.edit_PPI_layer_thickness      = 180;

% max distance from seabed at which PPI should be removed. This is
% an observed parameter and depends on the clarity of the water.
% Check Figure 14 to see whether this should be changed.
params.edit_PPI_max_hab              = 1000;

% set this vector to enable skipping of ensembles; skipping vector
% is wrapped around, i.e. [1 0] skips all odd ensembles, [0 1 0] skips
% ensembles 2 5 8 11.... This filter is useful to process the casts
% with only half the data to see whether the two halves agree, which
% probably means that the cast can be trusted. Note that if staggered
% ping setup is used to avoid PPI, the skipping vector should leave
% adjacent ensembles intact, i.e. use something like [1 1 0 0] and
% [0 0 1 1].
params.edit_skip_ensembles           = [];

% a detection alogrithm for asynchronous ping interference between
% master and slave has been developed. This is by default off, as
% we assume that the system is run synchronous
params.detect_asynchronous           = 0;

% bottom depth derived from data
% this one is used later for editing data
% if  0    : will be calculated, if data is available
%     nan  : will not be used
params.zbottom                       = 0;
params.zbottomerror                  = 0;

% from experience it appears as if the most distant data containing
% bin is very often not good. This can be seen in Plot 3 where the
% fringes of the data in the leftmost subplot are colored. 
% With this parameter this data is always discarded. 
params.edit_mask_last_bin            = 0; 

% discard all values in bins higher than the first one that is below
% the threshold the two values are for down and up looking instruments
% if there is only a single value, it will be applied to both
params.minimum_correlation_threshold = [0,0];

%% MISC OTHER
messages.warn                        = 'LADCP WARNINGS';
messages.warnp                       = 'LADCP processing warnings: ';

% LADCP cast number
params.ladcp_cast                    = 1;
params.warnp                         = [];

% serial numbers of instruments this is just used in one plot
% overwrite them in cruise_params.m
params.down_sn                       = nan;
params.up_sn                         = nan;

% distance between up and downlooker this will be added in rdiload 
% to the distance of the first bin from the uplooking instrument
params.dist_up_down                  = 0;

% what is the format of the output plots can be multiple ones, 
% separated by comma; e.g.  params.print_formats = 'ps,jpg,png';
params.print_formats                 = 'ps';

% show version
%disp(params.software);                       
p                                    = params;
clear params
