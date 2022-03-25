function   [data,messages] = calc_sadcp2_av(data,params,values,messages)
% function   [data,messsages] = calc_sadcp_av(data,params,values,messages)
%
% averages shipboard ADCP profiles close in time 
% to the LADCP cast
% 
% input  :	data		- LADCP data structure
%		messages	- LADCP message structure
%
% output  :	data		- LADCP data structure
%		params		- LADCP parameter structure
%		values		- LADCP values structure
%		messages	- LADCP messages structure
%
% version 0.6	last change 13.07.2012

% orig. M.Visbeck & A.Thurnherr, LDEO
% modified by G.Krahmann, IFM-GEOMAR

% check for input vector orientation                   GK  Dec 2006    0.1-->0.2
% remove bins with higher error than others            GK  Jul 2007    0.2-->0.3
% modified error calculation                           GK  Sep 2007    0.3-->0.4
% modifies to skip when file is not there              MV  Jul 2008    0.4-->0.5
% renamed cosd and sind to cos_d and sin_d             GK, 13.07.2012  0.5-->0.6

%
% general function info
%

%
% create empty sadcp data array
%
data.svel2 = [];

%
%check if sadcp data file was loaded else retrun
%
% if values.sadcpdata==0
%     return
% end


disp(' ')
disp('CALC_sadcp_AV:  average second sadcp data over the cast time')

%
% find all the sadcp data within the profile timeframe + sadcp_dtok
%
ind = find( data.tim_sadcp2 > values.start_time-params.sadcp2_dtok &...
	   data.tim_sadcp2 < values.end_time+params.sadcp2_dtok );


%
% check if sadcp position matches the LADCP position
% if not, display data but do not extract
%
if (abs(mean(data.lon_sadcp2(ind))-values.lon)>0.1/cos_d(values.lat) ||...
      abs(mean(data.lat_sadcp2(ind))-values.lat)>0.1)

  disp('>   Position of second sadcp data is more than 0.1 degree away from LADCP')
  disp('>     Not using second sadcp data')
  
  figure(2)
  clf
  orient tall
  subplot(211)
  text(0,0.5,' second sadcp data is more than 0.1 degree away from LADCP',...
            'color','r','fontsize',12,'fontweight','bold')
  axis off
  subplot(212)
  plot(data.lon_sadcp2(ind),data.lat_sadcp2(ind),'rp')
  hold on
  if isfield(data,'slon')
    plot(data.slon2,data.slat2,'.g')
  end
  if abs(values.lon)+abs(values.lat)~=0
    plot(values.lon,values.lat,'pr')
    plot(values.start_pos(2),values.start_pos(1),'bp','markersize',15)
    plot(values.end_pos(2),values.end_pos(1),'kp','markersize',15)
  end
  title('ship nav (g.) start (bp) end (kp) sadcp (rp)')
  xlabel('longitude')
  ylabel('latitude')
%  streamer([params.name,' Figure 9']);
  suplabel([params.name,' Figure 9'],'t');
  pause(0.001)
  return; 
end
 
 
%
% catch case when all sadcp data is garbage
% e.g. because of thruster use
%
if length(find(isfinite(data.u_sadcp2(:,ind))))<1
  disp('>   second sadcp data exists, but no overlapping finite second sadcp data found ')
  disp('>     This is typically caused by rough weather or thruster use.')
  return; 
end


% 
% extract sadcp data
%
disp(['    Found ',int2str(length(ind)),' second sadcp profiles ']) 
u = squeeze(data.u_sadcp2(:,ind));
v = squeeze(data.v_sadcp2(:,ind));

%
% remove value if only one value at a depth level
%
% for n = 1:length(u(:,1))
%     indr = find(~isnan(u(n,:)));
%     if length(indr)==1
%        u(n,indr) = NaN; 
%     end
%     indr = find(~isnan(v(n,:)));
%     if length(indr)==1
%        v(n,indr) = NaN; 
%     end
% end

%
% compute velocity standard deviation
%
if numel(u) == length(u)
  v_err = u*0+0.1;
else
  v_err = (nstd(u')+nstd(v'))';
  u     = nmean(u')';
  v     = nmean(v')';
end
ij        = find(v_err==0);
v_err(ij) = max([0.1,nmax(v_err)]);
nvel      = sum(isfinite(u+v)')'+v_err*0;
% new error determination
%v_err = v_err*max(nvel)./nvel;
dummy     = v_err*0+0.2;
for n=1:size(u,2)
  dummy(:,n+1) = v_err;
end
v_err     = nmean(dummy,2);
z         = data.z_sadcp2;


%
% compose output array
%
izok      = find(isfinite(u+v));
z         = z(:);
u         = u(:);
v         = v(:);
v_err     = v_err(:);
z         = z(izok);
u         = u(izok);
v         = v(izok);
v_err     = v_err(izok);


%
% blank out data with uncertainty larger than twice the median
% uncertainty or data where only a single sadcp value was used
%
med_v_err = nmedian(v_err);
good      = find( v_err < 2*med_v_err );
bad       = find( v_err >= 2*med_v_err );
disp(['    Removed ',int2str(length(bad)),' sadcp bins because of high error ']) 
z         = z(good);
u         = u(good);
v         = v(good);
v_err     = v_err(good);


%
% compose data array
%
data.svel2 = [z,u,v,v_err];


%
% remove shipboard ADCP data below maximum LADCP depth
% since we do not want to base velocities solely on sadcp
%
if ~isempty(data.svel2)
  good      = find( data.svel2(:,1) < values.maxdepth );
  data.svel2 = data.svel2(good,:);
end


%
% plot some results
%
figure(2)
clf

subplot(221)
plot(squeeze(data.u_sadcp2(:,ind)),data.z_sadcp2,'.r')
hold on
plot(data.svel2(:,2),data.svel2(:,1),'-k','linewidth',4)
plot(data.svel2(:,2),data.svel2(:,1),'-r','linewidth',2)
std_u2 = nstd(data.u_sadcp2(:,ind),[],2);
plot(data.svel2(:,2)+std_u2(good),data.svel2(:,1),'--k')
plot(data.svel2(:,2)-std_u2(good),data.svel2(:,1),'--k')
title('U')
ylabel('depth [m]')
grid
set(gca,'Ydir','reverse');
xlabel('velocity [m/s]')

subplot(222)
plot(squeeze(data.v_sadcp(:,ind)),data.z_sadcp,'.g')
hold on
plot(data.svel2(:,3),data.svel2(:,1),'-k','linewidth',4)
plot(data.svel2(:,3),data.svel2(:,1),'-g','linewidth',2)
std_v2 = nstd(data.v_sadcp2(:,ind),[],2);
plot(data.svel2(:,3)+std_v2(good),data.svel2(:,1),'--k')
plot(data.svel2(:,3)-std_v2(good),data.svel2(:,1),'--k')
title('V')
grid
set(gca,'Ydir','reverse');
xlabel('velocity [m/s]')

subplot(212)
plot(data.slon,data.slat,'.g')
hold on
plot(data.lon_sadcp2(ind),data.lat_sadcp2(ind),'rp')
plot(values.start_pos(2),values.start_pos(1),'bp','markersize',15)
plot(values.end_pos(2),values.end_pos(1),'kp','markersize',15)
title('ship nav (g.) start (bp) end (kp) sadcp (rp)')
xlabel('longitude')
ylabel('latitude')


suplabel([params.name,' sadcp'],'t');

hgsave('tmp/9');
