% Parameters setting files are called in this order
%
% default_params.m
% cruise_params.m   <--- you are here
% cast_params.m
%
% this is the location to enter special settings which apply
% to a whole cruise or to your special LADCP system setup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MISC OTHER
% set the  Cruise id this will appear on the top of all plots
% and in all file names
p.forced_adcp_ctd_lag        = 0;

% some software does only record the day of the year to be able to process 
% such data properly enter the year which will be used for data without 
% year information
% if you are measuring over newyear, you will need to introduce an
% if-statement here
p.correct_year               = 2021;
%ps.up_dn_looker              = 2;
% If you want you can give the serial numbers of up and down instrument
% this is just used in one plot
p.down_sn                    = 24543;
p.up_sn                      = 12818;
p.batt_type                  = '10S3P'; 

p.dist_up_down               = 1.6;

p.print_formats              = 'png';

%% SUPER ENSEMBLES 
% Output resolution and superensemble averaging depth 20 is good for 
% standard full ocean depth smaller (10 or even 5) can be used for special 
% shallow casts default is down-looker bin-length
p.dz	                     = 8;	    % output depth resolution
p.avens	                     = 10;		% pre-average data

%% CLEAN DATA
%OUTLIER detection is called twice once to clean the raw data
%	and a second time to clean the super ensembles
%        [n1 n2 n3 ...] the length gives the number of scans and
%	each value the maximum allowed departure from the mean in std
%	applied for the u,v,w fields for each bin over blocks 
%   of p.outlier_n profiles
% 2: very strong  3: medium  4:only largest outliers
p.outlier                    = [4];

% Standard thresholds, beyond which data will be discarded
% elim : ADCP internal error velocity limit   0.5 is reasonable and default
% vlim : ADCP horizontal velocity limit       2.5 is reasonable and default
% wlim : ADCP vertical velocity bin limit     0.2 is reasonable and default
% (wlim is the deviation from the median of all bins in each ensemble)
% 	maximum value for abs(V-error) velocity
p.elim                       = 0.5;
% 	maximum value for horizontal velocity 
p.vlim                       = 2.5;
% 	minimum value for %-good
p.pglim                      = 30;
%	maximum value for W difference between the mean W and actual
%        W(z) for each profile. 
p.wlim                       = 0.20;

%TILT  flag data with large tilt or tilt differences as bad
% [22  (max tilt allowed) 
% 4 (maximum tilt difference between pings allowed)]
% WH systems have reported decent profiles with up to 35 deg tilt ...
p.tiltmax                    = [20 4];
%%p.tiltmax                    = [30 8];

%% REFERENCE LAYER & PRESSURE SENSOR
% Give bin number for the best W to compute depth of the ADCP
% default uses bin 2-3 but be careful when up/down instruments
% are used. The good bins are in the middle! 
p.trusted_i                  = [2:3];

%% POSITION PARAMETERS
% navigation error in m
%
% This one is later used to determine the weight of the ship
% movement constraint. It should be set to something like the
% uncertainty of the position of the CTD when it is coming on 
% deck. I.e. the GPS error plus something accounting for the
% position difference between GPS antenna and CTD (remember
% the ship can rotate !).
% 30 m is a reasonable number.
p.nav_error                  = 30;

%% TIME/DEPTH PARAMETERS
% restrict time range to profile and disregard data close to surface
% p.cut = 0 dont restrict
% p.cut > 0 restrict time to adcp depth below a depth of p.cut
p.cut                        = 0;

% Offset correction
% if 1 remove velocity offset between up and down looking ADCP
% this will correct errors due to tilt biases etc.
p.offsetup2down              = 1;

%% MAGNETIC PARAMETERS
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
p.up2down                    = 0;

% how to best adjust compass to best match 
% if 1 rotate up-looking and down-looking instrument to mean heading
%    2 rotate up-looking and down-looking velocities to match up velocities
%        (not really recommended and very likey buggy !!!)
%    3 rotate up-looking velocities to down heading
%        (use if you suspect that the up heading is bad)
%    4 rotate down-looking velocities to up heading
%        (use if you suspect that the down heading is bad)
p.rotup2down                 = 1;

%% PARAMETERS FOR EDIT_DATA
% Set to 1 to remove data contaminated by previous-ping interference.
% NB: using the spike filter seems to work more robustly, as long
% as staggered pings are used.
p.edit_PPI                   = 0;
% PPI layer thickness in meters; the value is taken directly from Eric
% Firing's default (2*clip_margin = 180m).
p.edit_PPI_layer_thickness   = 50;

% Set list of bins to always remove from data.
p.edit_mask_up_bins          = 1;
p.edit_mask_dn_bins          = 1;

% Set to finite value to implement time-domain spike filter on the data; 
% this removes interference from other acoustic instruments but,
% more importantly, can get rid of PPI when staggered pings are used.
% Spike filtering is done using 2nd-difference
% peak detection in time. This parameter gives the maximum target-strength
% 2nd derivative that's allowed. Set to larger values to weaken the 
% filtering. (Check figure 14 to see if filter is too strong or too weak.)
% has been normalized to handle different instruments 
% old values from pre-10 versions will not work !!!  GK
p.edit_spike_filter_max_curv = NaN;

% a detection alogrithm for asynchronous ping interference between
% master and slave has been developed. This is by default off, as
% we assume that the system is run synchronous
p.detect_asynchronous        = 0;

%% SHEAR weight
%p.numtest                    = '1';
ps.smallfac                  = [0 0];

%% SADCP weight
p.use_sadcp                  = 0;
ps.sadcpfac                  = 0;

%% SADCP-2 weight
p.use_sadcp2                 = 0;
ps.sadcpfac2                 = 0;

%% DVL weight
p.use_dvl                    = 0;
ps.dvlfac                    = 0;

%% SMOOTHING weight
ps.smoofac                   = 0.5;

%% Barotropic weight
ps.barofac                   = 1;

%% BOTTOM TRACK weight
% Weight for the bottom track constraint
ps.botfac                    = 0;
p.btrk_used                  = 0;	
% mode = 1 :   use only RDI bottom track
%        2 :   use only own bottom track
%        3 :   use RDI, if existent, own else (default)
%        0 :   use not bottom track at all
p.btrk_mode                  = 3;
% p.btrk_ts is in dB to detect bottom above bin1 level (for own btm track)
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
p.btrk_ts                    = 50;
