function plot_rawinfo(d,params,values)
% function plotraw(d,params,values)
%
% plot some results
%
% version 0.4	last change 16.11.2012

% M.Visbeck, G.Krahmann, IFM-GEOMAR

% wrong bins picked looking for broken beam	              GK, Sep 2007	0.1-->0.2
% add colors to identify beam performance, more comments  GK, 20.05.2011  0.2-->0.3 
% use sfigure instead of figure                           GK, 16.11.2012  0.3-->0.4

%
% open and clear figure
%
sfigure(2);
clf
orient tall


%
% do not plot all points since that takes too long and
% creates too large postscript files
% thus reduce the used indices to maximum of 200
%
if length(d.time_jul)>200
  ind = fix(linspace(2,length(d.time_jul)-2,200));
else
  ind = [1:length(d.time_jul)];
end


%
% top subplot with vertical velocities for all bins
%
subplot(411)
z  = -d.izm(:,1)+d.z(1);
zz = [];
rw = [];
dz = [];


%
% find three beam solutions
% a profile is considered 3-beam if half of the good data are 3-beam
%
% they will be specially marked in this plot
%
iz   = fliplr(d.izu);
n3bu = 0;
n3bd = 0;
if length(iz)>1
  dzu  = nmedian(diff(d.zu));
  zz   = [zz;-z(iz)];
  dz   = [dz,iz*0+dzu];
  rw   = [rw;d.raw_w(iz,ind)+d.weight(iz,ind)*0];
  % check for 3-beam solutions
  iw   = sum(~isnan(d.raw_w(iz,ind)));
  ie   = sum(~isnan(d.raw_e(iz,ind)));
  i3bu = find(iw>(2*ie));
  n3bu = length(i3bu)/length(ind)*100;
end
iz = d.izd;
if length(iz)>1
  dzd  = nmedian(diff(d.zd));
  zz   = [zz;-z(iz)];
  dz   = [dz,iz*0+dzd];
  rw   = [rw;d.raw_w(iz,ind)+d.weight(iz,ind)*0];
  % check for 3-beam solutions
  iw   = sum(~isnan(d.raw_w(iz,ind)));
  ie   = sum(~isnan(d.raw_e(iz,ind)));
  i3bd = find(iw>(2*ie));
  n3bd = length(i3bd)/length(ind)*100;
end


%
% contour results
%
col = jet(64);
col = ([[1 1 1]; col]);
colormap(col)
gcolor(ind,zz,nmedian(diff(ind))*ones(1,length(ind)),dz,rw);
hold on
ax  = axis;
plot(ind([1 end]),[0 0],'-k');
pos = get(gca,'Position');
colorbar('vert','position',[.92 pos(2) .02 pos(4)])


%
% mark 3-beam solutions
%
if n3bu>10
  l3b       = NaN*ind;
  l3b(i3bu) = ax(3);
  plot(ind,l3b,'-r','linewidth',8)
  text(mean(ax(1:2)),ax(4),['found ',int2str(n3bu),...
	'% profiles 3 beam solutions'],...
	'VerticalAlignment','top','HorizontalAlignment','center','fontsize',11)
end
if n3bd>10
  l3b       = NaN*ind;
  l3b(i3bd) = ax(4);
  plot(ind,l3b,'-r','linewidth',8)
  text(mean(ax(1:2)),ax(3),['found ',int2str(n3bd),...
	'% profiles 3 beam solutions'],...
 	'VerticalAlignment','bottom','HorizontalAlignment','center',...
	'fontsize',11)
end

ylabel('range [m]')
xlabel('ensemble')
if isfield(params,'name')
  streamer([params.name,' Figure 2']);
end
title(' W as function of bindepth and time')


%
% subplot showing beam performance (target strength/echo amplitude)
%
% definition of the performance value is below in the subroutine checkbeam
%
cols = 'brgk';
if isfield(d,'tsd_m')
  subplot(427)
  for ii = 1 :length(d.tsd_m(1,:))
      hold on
    plot(d.tsd_m(1:length(d.izd),ii),-d.zd,cols(ii))
  end
  axis tight
  ax = axis;
  if isfield(d,'tsu_m')
    hold on
    for ii = 1 :length(d.tsu_m(1,:))
        plot(d.tsu_m(1:length(d.izu),ii),d.zu,cols(ii))
    end
    axis tight
    ax = axis;
    plot(ax(1:2),ax(1:2)*0,'-k')
  end

  t = d.tsd_m;
  checkbeam(t,ax,1)

  if isfield(d,'tsu_m')
    t = d.tsu_m;
    checkbeam(t,ax,0)
  end
  axis(ax)
  ylabel('distance [m]')
  xlabel('median echo amplitude [dB]')
  title('Beam Performance (S2N / best beam S2N)')
end


%
% subplot showing range and correlation
%
%
% range is derived in rdiload.m
% and defined as the distance at which the correlation has dropped off to
% less than 30% of the highest correlation of the first bin (of all 4
% beams)
%
if isfield(d,'cmd_m')
  subplot(428)
  for ii = 1 : length(d.cmd_m(1,:))
      hold on
    plot(d.cmd_m(1:length(d.izd),ii),-d.zd,cols(ii))
  end
  axis tight
  ax                = axis;
  [dum,dum,dum,x,y] = makebars(-d.zd,sum(isfinite(d.weight(d.izd,:))'));
  hold on
  fill(-y/max(y)*10,x,'r')

  if isfield(d,'cmu_m')
    hold on
    for ii = 1 : length(d.cmu_m(1,:))
        plot(d.cmu_m(1:length(d.izu),ii),d.zu,cols(ii))
    end
    plot(ax(1:2),ax(1:2)*0,'-k')
    [dum,dum,dum,x,y] = makebars(d.zu,sum(isfinite(d.weight(d.izu,:))'));
    fill(-y/max(y)*10,x,'g')
    axis tight
    ax = axis;
    for n=1:4
      text((0.12*n+0.27)*ax(2),ax(4),int2str(params.up_range(n)),...
        'VerticalAlignment','top','color',cols(n))
    end
    if ~isnan(params.up_sn)
        text(0.01*ax(2),ax(4),['#',int2str(params.up_sn),...
          ' range:'],'VerticalAlignment','top')
    elseif ~isnan(values.inst_serial(2))
        text(0.01*ax(2),ax(4),['#',int2str(values.inst_serial(2)),...
          ' range:'],'VerticalAlignment','top')
    else
        text(0.01*ax(2),ax(4),['range:'],'VerticalAlignment','top')
    end
  end
  ax(1) = -13; 

  for n=1:4
    text((0.12*n+0.27)*ax(2),ax(3),int2str(params.dn_range(n)),...
      'VerticalAlignment','bottom','color',cols(n))
  end
  if ~isnan(params.down_sn)
      text(0.01*ax(2),ax(3),['#',int2str(params.down_sn),...
        ' range:'],'VerticalAlignment','bottom')
  elseif ~isnan(values.inst_serial(1))
      text(0.01*ax(2),ax(3),['#',int2str(values.inst_serial(1)),...
        ' range:'],'VerticalAlignment','bottom')
  else
      text(0.01*ax(2),ax(3),['range:'],'VerticalAlignment','bottom')
  end
  axis(ax)
  ylabel('distance [m]')
  xlabel('median correlation [ADCP units]')
  title('Range of good data (>30% of peak corr)')
  
end


%
% subplot showing depth of the package
%
if isfield(d,'z')
  subplot(813)
  plot(-d.z)
  ylabel('depth')
  ax = axis;
  ax(3) = 0;
  ax(4) = -min(d.z*1.05);
  ax(2) = length(d.z);
  axis(ax)
  set(gca,'Ydir','reverse');
end


%
% subplot showing the tilt of the package
%
if isfield(d,'tilt')
  subplot(814)
  plot(d.tilt(1,:))
  hold on
  ax = axis;
  patch(ax([1,2,2,1]),[20,20,30,30],[1,0.75,0.75],'edgecolor','none')
  patch(ax([1,2,2,1]),[30,30,40,40],[1,0.5,0.5],'edgecolor','none')
  plot(d.tilt(1,:))
  ylabel('tilt [deg]')
  ax(2) = length(d.z);
  ax(4) = 30;
  axis(ax)
  set(gca,'yaxislocation','right')
end


%
% subplot showing the heading of the package
%
if isfield(d,'hdg')
  subplot(815)
  plot(d.hdg(1,:))
  ylabel('heading [deg]')
  ax    = axis;
  ax(4) = 360;
  ax(2) = length(d.z);
  axis(ax )
  set(gca,'YTick',[0 90 180 270 360])
end


%
% subplot showing the transmit voltage of the instruments
%

%Determine voltage
if strcmp(params.down_sn, '23909')
    xmv      = [72, 91, 110, 128, 146, 165, 183, 201];
    xvoltage = [20:5:55];
else
    xmv      = [72, 91, 110, 128, 146, 165, 183, 201];
    xvoltage = [20:5:55];    
end
mes_voltage  = interp1(xmv, xvoltage, d.xmv(1,:));  

%Determine percentage
if strcmp(params.batt_type, '10S3P')
    params.lim_inf = 36.8;
    voltage = [32, 33.76, 34.61, 35.43, 36.04, 36.47, 36.67, 36.74, 36.77, 36.80, 36.82,...
                             36.84, 36.85, 36.87, 36.89, 36.95, 37.06, 37.43, 37.75, 37.90, 38.19,...
                             38.89, 39.45, 40.12, 40.94, 41.90, 42];
    percent = [0, 1.6, 2.5, 3.5, 4.5, 5.5, 6.5, 7.4, 8.4, 9.4, 10.4, 11.4, 12.3, 13.3, 14.3,...
                            15.3, 16.3, 21.1, 30.9, 40.6, 50.4, 60.2, 70.0, 79.7, 89.5, 99.3, 100];                    
elseif strcmp(params.batt_type, '13S2P')
    params.lim_inf = 47.9;
    voltage = [54.60, 54.47, 53.22, 52.16, 51.29, 50.56, 49.65, 49.27, 49.08, 48.66, 48.18,...
                             48.04, 47.96, 47.93, 47.91, 47.89, 47.87, 47.84, 47.80, 47.76, 47.67,...
                             47.41, 46.85, 46.06, 44.99, 43.89, 41.60];
    percent = [100.0, 99.3, 89.5, 79.7, 70.0, 60.2, 50.4, 40.6, 30.9, 21.1, 16.3, 15.3, 14.3,...
                             13.3, 12.3, 11.4, 10.4, 9.4, 8.4, 7.4, 6.5, 5.5, 4.5, 3.5, 2.5,...
                             1.6, 0.0];
end

mes_percent = interp1(voltage, percent, mes_voltage(end));

if isfield(d,'xmv')
  subplot(816)
  plot(mes_voltage)
  hold on
  plot(params.lim_inf*ones(length(mes_voltage),1),'--r')
  hold off
  text(length(mes_voltage)/2,mean(mes_voltage),[' mean: ',...
	num2str(fix(mean(mes_voltage)*10)/10) 'V (SN' num2str(params.down_sn) ')'])
  text(length(mes_voltage)/2,mean(mes_voltage)-2,[' ending rate: ',...
	num2str(round(mes_percent*10)/10) '%'], 'Color', 'red')
  if mes_voltage <= params.lim_inf
      text(length(mes_voltage)/4,mean(mes_voltage),'RECHARGE BATTERY!!!', 'Color', 'red')
      text(3*length(mes_voltage)/4,mean(mes_voltage),'RECHARGE BATTERY!!!', 'Color', 'red')  
  end
  ylabel('Voltage [V]')
  xlabel('ensemble')
  ax    = axis;
  ax(2) = length(d.z);
  axis(ax)
  set(gca,'yaxislocation','right')
end

hgsave('tmp/2')






%=============================================
function checkbeam(t,ax,do)
% check beam performance
%
% it looks like 
%
% - calculate the noise level as meanmedian of the distant half of the echo
%   amplitude data
% - compare that with the echo amplitude of the first two bins
%   and call the ratio 'signal to noise ratio'
% - call all beams broken/bad/weak that are less than 0.5/0.65/0.8 of the
%   best beam
bl   = size(t,1);			% this seems to have been a bug
                            % the 1 was a 2 and thus picked
                            % the wrong dimension
iend = fix(bl/2):bl;

tax  = mean(ax(1:2));
if do
  tay   = ax(3);
  tflag = 'bottom';
else
  tay   = ax(4);
  tflag = 'top';
end

for i=1:4
  % first correct for source level
  t(:,i) = t(:,i)-mean(t(:,i));
  % find noise level
  tn(i)  = meanmediannan(t(iend,i),2);
  s2n(i) = mean(t(1:2,i))-tn(i);
  if s2n(i) == 0
    s2n(i) = 1e100;
  end
end

ifail = s2n<max(s2n)*0.5;
ibad  = ~ifail & s2n<max(s2n)*0.65;
iweak = ~ifail & ~ibad & s2n<max(s2n)*0.8;
cols = 'brgk';
for i=1:4
  text(ax(1)+0.2*i*diff(ax(1:2)),tay,[int2str(s2n(i)./max(s2n)*100),'%'],...
 	'VerticalAlignment',tflag,'color',cols(i))
end

if sum(ifail)>0
  it = find(ifail==1);
  text(tax,tay*0.5,[' beam ',int2str(it),' broken'],...
 	'VerticalAlignment',tflag,'HorizontalAlignment','center','fontsize',14)
end

if sum(ibad)>0
  it = find(ibad==1);
  text(tax,tay*0.65,[' beam ',int2str(it),' bad'],...
 	'VerticalAlignment',tflag,'HorizontalAlignment','center','fontsize',12)
end

if sum(iweak)>0
  it = find(iweak==1);
  text(tax,tay*0.8,[' beam ',int2str(it),' weak'],...
 	'VerticalAlignment',tflag,'HorizontalAlignment','center','fontsize',10)
end
