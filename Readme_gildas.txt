- ajout en bas dans le .bashrc
- source ~/.bashrc
- verifier les var d'env CRUISE, DRIVE etc ..

cd ~/DATA/CRUISES/RESILIENCE
chmod 755 ./local/sbin/*
./local/sbin/process-all.sh $CRUISE $CRUISEid $DRIVE

# installation de perl et des modules qui vont bien
Many information
==> https://us191.ird.fr/spip.php?article77


=> Oceano module
cd ~/local/src
git clone https://forge.ird.fr/us191/oceano.git
cd oceano/lib/perl/Oceano
perl Makefile.PL
make
sudo make install


# For linux:
sudo apt install gcc g++ make netcdf-bin libnetcdf-dev libnetcdff-dev perl-doc libswitch-perl libdate-manip-perl libxml-libxml-perl libconfig-tiny-perl pdl libpdl-netcdf-perl

conda install pandas
conda install -c conda-forge iris xarray toml netCDF4 simplekml cartopy cartopy_offlinedata

pip install julian lat-lon-parser

# For mac  : GROSSE GALERE, Jacques conseilles la VM ubuntu
1) brew install perl

# Not used
"By default non-brewed cpan modules are installed to the Cellar. If you wish
for your modules to persist across updates we recommend using `local::lib`."
PERL_MM_OPT="INSTALL_BASE=$HOME/perl5" cpan local::lib
echo 'eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"' >> /Users/gcambon/.bash_profile
export ARCHFLAGS="-arch i386 -arch x86_64"
export VERSIONER_PERL_PREFER_32_BIT=no


2) brew install cpanm


3)
sudo cpanm XML::LibXML
sudo cpanm Date::Manip
sudo cpanm Switch
sudo cpanm PDL

export PERL5LIB=/usr/local/Cellar/perl/5.34.0/lib/perl5/site_perl/	5.34.0

Config::Tiny module
Date::Manip module

=> MARCHE PAS
