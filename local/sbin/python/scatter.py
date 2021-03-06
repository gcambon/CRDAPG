#!/usr/bin/env python
from netCDF4 import Dataset
from os.path import expanduser
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import cartopy
cartopy.config['pre_existing_data_dir'] = expanduser('~/miniconda3/share/cartopy')
import cartopy.crs as ccrs
import os

CRUISE=os.environ['CRUISE']
file = '../../../data-processing/THERMO/netcdf/OS_' + CRUISE + '_TSG.nc'
ncpath = ''
path = '../../../data-processing/THERMO/plots'

ncfile = os.path.join(ncpath, file)
nc = Dataset(ncfile, mode='r')

SSPS = nc.variables['SSPS']
SSTP = nc.variables['SSTP']
TIME = nc.variables['TIME']
LATITUDE = nc.variables['LATITUDE']
LONGITUDE = nc.variables['LONGITUDE']
CM = nc.cycle_mesure

########################################
# parameters
## bounding
latmin = -32.5
latmax = -31.5
#
lonmin = 29
lonmax = 30.1

##caxis
vmin_salt = 35.2
vmax_salt = 35.5

vmin_temp = 21
vmax_temp = 25
#
markersize = 25

#########################################

fig = plt.figure(figsize=(6, 12))
gs = gridspec.GridSpec(2,1)
ax1 = plt.subplot(gs[0], projection=ccrs.Mercator())
ax1.set_extent([lonmin, lonmax, latmin, latmax], crs=ccrs.PlateCarree())
ax1.coastlines(resolution='auto', color='k')
ax1.gridlines(color='lightgrey', linestyle='-', draw_labels=True)

im1 = ax1.scatter(LONGITUDE[:], LATITUDE[:], c=SSPS[:], s=markersize, cmap='jet', vmin=vmin_salt, vmax=vmax_salt, transform=ccrs.PlateCarree())
fig.colorbar(im1, ax=ax1, orientation='vertical', pad=0.15)
ax1.set(xlabel='{} '.format(LONGITUDE.standard_name), ylabel='{} '.format(LATITUDE.standard_name),
        title='{} - {}'.format(CM, SSPS.long_name))

ax2 = plt.subplot(gs[1], projection=ccrs.Mercator())
ax2.set_extent([lonmin, lonmax, latmin, latmax], crs=ccrs.PlateCarree())
ax2.coastlines(resolution='auto', color='k')
ax2.gridlines(color='lightgrey', linestyle='-', draw_labels=True)

im2 = ax2.scatter(LONGITUDE[:], LATITUDE[:], c=SSTP[:], s=markersize, cmap='jet', vmin=vmin_temp, vmax=vmax_temp, transform=ccrs.PlateCarree())
fig.colorbar(im2, ax=ax2, orientation='vertical', pad=0.15)
ax2.set(xlabel='{} '.format(LONGITUDE.standard_name), ylabel='{} '.format(LATITUDE.standard_name),
        title='{} - {}'.format(CM, SSTP.long_name))

figname = '{}_TSG_COLCOR_SCATTER.png'.format(CM)
dest = os.path.join(path, figname)
fig.savefig(dest)
print('Printing: ', dest)

#plt.show()
#plt.cla()
plt.close(fig)
