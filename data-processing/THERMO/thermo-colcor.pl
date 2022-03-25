#!/usr/bin/perl -w
#
# thermo-colcor.pl   J Grelet IRD mars 2016
# $Id$
# analyse des fichiers thermo du suroit campagne PIRATA-FR26
# du 07/03/2016 au 13/04/2016
# fichiers colcor transmis a Coriolis (mediane) avec la meteo
# Ce sont des fichiers de messagerie incluant la trame nmea a decoder:
# $PIFM,SUCOR,28/04/2011,06:02:45,N,05,29.083,E,02,26.890,0,GPS,14,THSAL,045,045,045,045,029.596,029.737,005.774,034.770,METEO,027,027,027,027,027,000,027,0029.200,029.700,080.00,1010.00,0021.00,0000.00,0025.400,
#
# usage ./thermo-fr26.pl
#

use strict;
use Time::Local;
use Date::Manip;
use File::Basename;
use Getopt::Long;
if ( defined($PDL::SHARE) ) { }
use PDL;
use PDL::Math;
use Config::Tiny;

#------------------------------------------------------------------------------
# Les repertoires de sorties
#------------------------------------------------------------------------------
my $ascii_dir = 'ascii/';
my $odv_dir   = 'odv/';
my $tsgqc_dir = 'tsgqc/';

#------------------------------------------------------------------------------
# Les variables globales
#------------------------------------------------------------------------------
our $VERSION = '1.0';
my $debug = 0;
my $echo;
my $dtd = 'public';
my $dtdLocalPath;
my $encoding;

# a mettre sous forme d'argument ligne de commande

my $institute;
my $author;
my $type;
my $sn;
my $pi;
my $creator;
my $acquisitionSoftware;
my $acquisitionVersion;
my $processingSoftware;
my $processingVersion;
my $cycle_mesure;
my $plateforme;
my $context;
my $timezone;
my $format_date;
my $processing_code;
my $begin_date;
my $end_date;
my $cruisePrefix;
my $stationPrefixLength;
my $title_summary;
my $comment;

my $version;
my $help;
my $xml   = 1;
my $ascii = undef;
my $tsgqc = undef;
my $gps   = 0;
my $all   = undef;
my $loop  = 0;

# noms des fichiers
my $tsg_dot_file   = undef;
my $tsg_ascii_file = undef;
my $tsg_xml_file   = undef;
my $tsg_qc_file    = undef;
my $gps_dot_file   = undef;

# handles de fichiers
my $tsg_dot_hdl   = undef;
my $tsg_ascii_hdl = undef;
my $tsg_xml_hdl   = undef;
my $tsg_qc_hdl    = undef;
my $gps_dot_hdl   = undef;

my ( $j, $dif_met, $dif_sbe );
my ( $date, $heure );
my ( $julien, $time, $month, $year, $day, $hour, $min, $sec );
my ( $lat_s,  $lat_deg,  $lat_min,  $lat_dec );
my ( $long_s, $long_deg, $long_min, $long_dec );

# capteurs
# TSG
my ( $SSTP, $SSJT, $CNDC, $SSPS, $P, $sigmateta, $sndvel );

# METEO
my ( $code, $lat, $long, $sonde, $tair, $tmer, $hum );
my ( $patm, $rad, $rosee, $dir, $vit, $cond, $sbe38, $sss, $sst_cuve );
my $ecart;

#------------------------------------------------------------------------------
# version()
#------------------------------------------------------------------------------
sub version() {
  print "Version: $version\nAuthor: $author\n\n";
  exit 1;
}

#------------------------------------------------------------------------------
# usage()
#------------------------------------------------------------------------------
sub usage() {
  print STDERR "\nusage: perl thermo-fr24.pl [options]  <files>\n\n";
  print STDERR
    "Options:\n    --help                 Display this help message\n";
  print STDERR "    --version              program version\n";
  print STDERR "    --debug=[1-3]          debug info\n";
  print STDERR "    --echo                 display filenames processed\n";
  print STDERR "    --ascii                ASCII output instead XML\n";
  print STDERR
"    --tsgqc                ASCII output format used by validation software tsgqc\n";
  print STDERR "    --xml                  XML output (default)\n";
  print STDERR
    "    --gps                  ASCII output position every hour for DD\n";
  print STDERR "    --all                  ASCII,XML and tsgqc output\n";
  print STDERR "    --local                use local DTD\n";
  print STDERR "\naccept short options like -d1 -t2\n\n";
  print STDERR
"Thermo processing example:\n------------\n\$ perl thermo-colcor.pl --tsgqc --echo --local --all data/*.COLCOR\n\n";
  exit;
}

#------------------------------------------------------------------------------
# get_options()
# analyse les options
#------------------------------------------------------------------------------
sub get_options() {

  &GetOptions(
    "ascii"   => \$ascii,
    "xml"     => \$xml,
    "tsgqc"   => \$tsgqc,
    "gps"     => \$gps,
    "all"     => \$all,
    "debug=i" => \$debug,
    "echo"    => \$echo,
    "local"   => \$dtd,
    "version" => \$version,
    "help"    => \$help
  ) or &usage;

  &version if $version;
  &usage   if $help;
  if ($all) { $ascii = $tsgqc = $xml = $gps = 1; }
}

#------------------------------------------------------------------------------
# fonctions de calcul de la position/date
#------------------------------------------------------------------------------
sub position {
  my ( $deg, $min, $hemi ) = @_;
  my $sign = 1;
  if ( $hemi eq "S" || $hemi eq "W" ) {
    $sign = -1;
  }
  return ( ( $deg + ( $min / 60 ) ) * $sign );
}

sub julian {
  my ( $jj, $h, $m, $s ) = @_;

  #print "$jj $h $m $s\n";
  my $tmp = ( ( $h * 3600 ) + ( $m * 60 ) + $s ) / ( 1440 * 60 );
  return ( $jj + $tmp );
}

#------------------------------------------------------------------------------
# Conversion d'une heure ou position exprime en decimal en sexagesimal
#------------------------------------------------------------------------------
sub HtoHMS {
  my ( $h1, $hemi ) = @_;

  my ( $Sign, $h, $m1, $mi, $s );
  if ( $hemi eq 'lat' ) {
    if ( $h1 < 0 ) {
      $Sign = 'S';
    }
    else {
      $Sign = 'N';
    }
  }
  elsif ( $hemi eq 'long' ) {
    if ( $h1 < 0 ) {
      $Sign = 'W';
    }
    else {
      $Sign = 'E';
    }
  }
  $h = $h1 < 0 ? ceil($h1) : floor($h1);
  $m1 = ( $h1 - $h ) * 60;

  $mi = $m1 < 0 ? ceil($m1) : floor($m1);
  $s = ( $m1 - $mi ) * 60;
  return ( abs($h), abs($mi), abs($s), $Sign );
}

#------------------------------------------------------------------------------
# entete TSGQC
#------------------------------------------------------------------------------
sub entete_tsgqc {
  my ($handle) = @_;

  print $handle "%PLATFORM_NAME $plateforme\n";
  print $handle
"%HEADER YEAR MNTH DAYX hh mi ss LATX LONX SSPS SSPS_QC SSPS_ADJUSTED SSPS_ADJUSTED_ERROR SSPS_ADJUSTED_QC SSJT SSJT_QC SSJT_ADJUSTED SSJT_ADJUSTED_ERROR SSJT_ADJUSTED_QC SSTP SSTP_QC SSTP_ADJUSTED SSTP_ADJUSTED_ERROR SSTP_ADJUSTED_QC\n";
}

#------------------------------------------------------------------------------
# entete XML
#------------------------------------------------------------------------------
sub entete_xml {
  my ( $handle, $software, $softVersion, $instrumentType, $INSTRUMENT_SN ) = @_;
  my $today = &UnixDate( &ParseDate("today"), "%d/%m/%Y" );

  print $handle '<?xml version="1.0" encoding="ISO-8859-1"?>' . "\n";

  # les commentaires ne sont pas acceptés par XML Toolbox Matlab de Geodise
  if ( defined $dtd ) {
    print $handle
      "<!DOCTYPE OCEANO SYSTEM \"$dtdLocalPath/local/oceano.dtd\">\n";
  }
  else {
    print $handle
'<!DOCTYPE OCEANO PUBLIC "-//US191//DTD OCEANO//FR" "http://www.brest.ird.fr/us191/database/oceano.dtd">'
      . "\n";
  }
  print $handle '<OCEANO TYPE="TRAJECTOIRE">' . "\n";
  print $handle "  <ENTETE>\n";
  print $handle "    <PLATEFORME>\n";
  print $handle "      <LIBELLE>$plateforme</LIBELLE>\n";
  print $handle "    </PLATEFORME>\n";
  print $handle
"    <CYCLE_MESURE CONTEXTE=\"$context\" TIMEZONE=\"$timezone\" FORMAT=\"$format_date\">\n";
  print $handle "      <LIBELLE>$cycle_mesure</LIBELLE>\n";
  print $handle "      <INSTITUT>$institute</INSTITUT>\n";
  print $handle "      <RESPONSABLE>$pi</RESPONSABLE>\n";
  print $handle
"      <ACQUISITION LOGICIEL=\"$software\" VERSION=\"$softVersion\"></ACQUISITION>\n";
  print $handle
    "      <TRAITEMENT LOGICIEL=\"$0\" VERSION=\"$VERSION\"></TRAITEMENT>\n";
  print $handle
"      <VALIDATION LOGICIEL=\"datagui\" VERSION=\"1.0\" DATE=\"$today\" OPERATEUR=\"$pi\" CODIFICATION=\"OOPC\">\n";
  print $handle "        <CODE>$processing_code</CODE>\n";
  print $handle "        <COMMENTAIRE>$title_summary</COMMENTAIRE>\n";
  print $handle "      </VALIDATION>\n";
  print $handle "    </CYCLE_MESURE>\n";
  print $handle "    <INSTRUMENT TYPE=\"$type\" NUMERO_SERIE=\"$sn\">\n";
  print $handle "    </INSTRUMENT>\n";
  print $handle "  </ENTETE>\n";
  print $handle "  <DATA>\n";
}

#------------------------------------------------------------------------------
# read string key inside section in config file
#------------------------------------------------------------------------------
sub read_config_string() {
  my ( $Config, $section, $key ) = @_;

  my $value = $Config->{$section}->{$key};
  if ( !defined $value ) {
    die "Missing string '$key' in section '$section' $!";
  }
  return $value;
}

#------------------------------------------------------------------------------
# read config.ini file where cruise parameter are defined
#------------------------------------------------------------------------------
sub read_config() {
  my ($configFile) = @_;

  # Create a config
  my $Config = Config::Tiny->new;

  $Config = Config::Tiny->read($configFile)
    or die "Could not open '$configFile' $!";

  $author       = &read_config_string( $Config, 'global', 'author' );
  $debug        = &read_config_string( $Config, 'global', 'debug' );
  $echo         = &read_config_string( $Config, 'global', 'echo' );
  $dtd          = &read_config_string( $Config, 'xml',    'dtd' );
  $dtdLocalPath = &read_config_string( $Config, 'xml',    'dtdLocalPath' );
  $encoding     = &read_config_string( $Config, 'xml',    'encoding' );
  $cycle_mesure = &read_config_string( $Config, 'cruise', 'cycle_mesure' );
  $plateforme   = &read_config_string( $Config, 'cruise', 'plateforme' );
  $context      = &read_config_string( $Config, 'cruise', 'context' );
  $timezone     = &read_config_string( $Config, 'cruise', 'timezone' );
  $format_date  = &read_config_string( $Config, 'cruise', 'format_date' );
  $processing_code =
    &read_config_string( $Config, 'cruise', 'processing_code' );
  $begin_date = &read_config_string( $Config, 'cruise', 'begin_date' );
  $end_date   = &read_config_string( $Config, 'cruise', 'end_date' );
  $institute  = &read_config_string( $Config, 'cruise', 'institute' );
  $pi         = &read_config_string( $Config, 'cruise', 'pi' );
  $creator    = &read_config_string( $Config, 'cruise', 'creator' );
  $acquisitionSoftware =
    &read_config_string( $Config, 'thermo', 'acquisitionSoftware' );
  $acquisitionVersion =
    &read_config_string( $Config, 'thermo', 'acquisitionVersion' );
  $processingSoftware =
    &read_config_string( $Config, 'thermo', 'processingSoftware' );
  $processingVersion =
    &read_config_string( $Config, 'thermo', 'processingVersion' );
  $type          = &read_config_string( $Config, 'thermo', 'type' );
  $sn            = &read_config_string( $Config, 'thermo', 'sn' );
  $title_summary = &read_config_string( $Config, 'thermo', 'title_summary' );
  $comment       = &read_config_string( $Config, 'thermo', 'comment' );
}

#------------------------------------------------------------------------------
# Debut du programme principal
#------------------------------------------------------------------------------
#&Date_Init( "TZ=UTC" );
&Date_Init('SetDate=now,UTC');
&read_config('../config.ini');
&usage if ( $#ARGV == -1 );
&get_options;

# creation des noms de fichiers
$tsg_ascii_file = lc $ascii_dir . $cycle_mesure . '_tsg' if ( defined $ascii );
$tsg_xml_file = lc $ascii_dir . $cycle_mesure . '_tsg.xml' if ( defined $xml );
$tsg_dot_file = lc $ascii_dir . $cycle_mesure . '.tsg'   if ( defined $ascii );
$tsg_qc_file  = lc $tsgqc_dir . $cycle_mesure . '.tsgqc' if ( defined $tsgqc );
$gps_dot_file = lc $ascii_dir . $cycle_mesure . '.gps'   if ( defined $gps );

print STDERR "Output: ";
print STDERR "ASCII "  if ( defined $ascii );
print STDERR "XML "    if ( defined $xml );
print STDERR "TSGQC\n" if ( defined $tsgqc );

# ouverture des fichiers
if ( defined $ascii ) {
  mkdir($ascii_dir) unless ( -d $ascii_dir );
  open( $tsg_ascii_hdl, "+> $tsg_ascii_file" )
    or die "Can't open file : $tsg_ascii_file\n";
  print $tsg_ascii_hdl "$cycle_mesure  $plateforme  $institute  $type $sn\n";
  print $tsg_ascii_hdl
    "YEAR     DAYD      LATX      LONX     SSJT    SSPS    CNDC    SSTP\n";

  open( $tsg_dot_hdl, "+> $tsg_dot_file" )
    or die "Can't open file : $tsg_dot_file\n";
  print $tsg_dot_hdl "$cycle_mesure  $plateforme  $institute  $type $sn\n";
  print $tsg_dot_hdl
" Julien     Date      Time     Latitude    Longitude    SSJT    SSPS    CNDC    SSTP\n";
}
if ( defined $gps_dot_file ) {
  mkdir($ascii_dir) unless ( -d $ascii_dir );
  open( $gps_dot_hdl, "+> $gps_dot_file" )
    or die "Can't open file : $gps_dot_file\n";
}

# ecriture des entetes
if ( defined $xml ) {
  mkdir($ascii_dir) unless ( -d $ascii_dir );
  open( $tsg_xml_hdl, "+> $tsg_xml_file" )
    or die "Can't open file : $tsg_xml_file\n";
  &entete_xml( $tsg_xml_hdl, $acquisitionSoftware, $acquisitionVersion, $type,
    $sn );
  print $tsg_xml_hdl
    "YEAR     DAYD      LATX      LONX     SSJT    SSPS    CNDC    SSTP\n";

#&entete_xml($mtod_hdl,$softwareMeteo, $softwareMeteoVersion, $INSTRUMENT_MTO, "");
#print $mtod_hdl "YEAR     DAYD      LATX       LONX     SSTP  DRYT  WMSP  WDIR   ATMS  RELH    RDIN\n";
}

if ( defined $tsgqc ) {
  mkdir($tsgqc_dir) unless ( -d $tsgqc_dir );
  open( $tsg_qc_hdl, "+> $tsg_qc_file" )
    or die "Can't open file : $tsg_qc_file\n";
  &entete_tsgqc($tsg_qc_hdl);
}

# parcourt des fichiers .eml
# ne decode que les lignes commencant par $PIFM,SUCOR
foreach my $file (@ARGV) {
  open( DATA_FILE, $file ) or warn( "Erreur: " . $! );
  print STDERR "Lit: $file\n" if defined $echo;
  while (<DATA_FILE>) {
    if (/^\$PIFM,TSCOR/) {
      (
        undef,    undef,   $date,     $heure,    $lat_s, $lat_deg,
        $lat_min, $long_s, $long_deg, $long_min, undef,  undef,
        undef,    undef,   undef,     undef,     undef,  undef,
        $SSTP,    $SSJT,   $CNDC,     $SSPS,     undef
      ) = split /,/;

      # decodage de la date et heure
      if ( $date =~ m[(\d+)/(\d+)/(\d+)] ) {
        ( $day, $month, $year ) = ( $1, $2, $3 );
      }
      if ( $heure =~ /(\d+):(\d+):(\d+)/ ) {
        ( $hour, $min, $sec ) = ( $1, $2, $3 );
      }

      # conversion en format US (MM/DD/YY) pour ParseDate
      $date =
          $month . "/"
        . $day . "/"
        . $year . " "
        . $hour . ":"
        . $min . ":"
        . $sec;

      #print STDERR  "Date: $date\n";
      $date = &ParseDate($date);

      # transforme le day_of_year en julian day
      $julien = &julian(
        &UnixDate( $date, "%j" ),
        &UnixDate( $date, "%H" ),
        &UnixDate( $date, "%M" ),
        &UnixDate( $date, "%S" )
      ) - 1;

      $lat_dec  = &position( $lat_deg,  $lat_min,  $lat_s );
      $long_dec = &position( $long_deg, $long_min, $long_s );

      # Seabird utilise le julien 1, datemanip 1
      #$julien = $julien -1;

     #$T68 = $T0 * 1.00024;
     #$sndvel=&sw_svel($S0,$T68,$P);
     #$sigmateta=&sw_sigmateta($S1,$T68,$P);
     # Returns the year, month, day, hour, minutes, and decimal seconds given
     # a floating point day of the year.
     #($year,$month,$day,$hour,$min,$sec) = &Date_NthDayOfYear($year,$julien+1);
      if ( defined $tsgqc ) {
        printf $tsg_qc_hdl
"%04d %02d %02d %02d %02d %02d   %+10.7f   %+11.7f %6.3f 0    NaN    NaN 0 %6.3f 0    NaN    NaN 0  %6.3f 0   NaN   NaN 0\n",
          $year, $month, $day, $hour, $min, $sec, $lat_dec, $long_dec,
          $SSPS, $SSJT, $SSTP;
      }
      if ( defined $ascii ) {
        printf $tsg_dot_hdl
"%7.4f %02d/%02d/%04d %02d:%02d:%02d  %2d°%02d.%02d %s  %3d°%02d.%02d %s  %6.3f  %6.3f  %6.3f  %6.3f\n",
          $julien, $day, $month, $year, $hour, $min, $sec,
          &HtoHMS( $lat_dec, 'lat' ), &HtoHMS( $long_dec, 'long' ),
          $SSJT, $SSPS, $CNDC, $SSTP;
        printf $tsg_ascii_hdl
          "%4d  %10.6f %+8.4f %+9.5f  %6.3f  %6.3f  %6.3f  %6.3f\n",
          $year, $julien, $lat_dec, $long_dec, $SSJT, $SSPS, $CNDC, $SSTP;
      }
      if ( defined $xml ) {
        printf $tsg_xml_hdl
          "%4d  %10.6f %+8.4f %+9.5f  %6.3f  %6.3f  %6.3f  %6.3f\n",
          $year, $julien, $lat_dec, $long_dec, $SSJT, $SSPS, $CNDC, $SSTP;
      }
      if ( defined $gps and $loop == 12 ) {
        printf $gps_dot_hdl
          "%04d%02d%02d%02d%02d %+6.3f %+6.3f %6.3f  %6.3f\n",
          $year, $month, $day, $hour, $min, $lat_dec, $long_dec, $SSTP, $SSPS;
        $loop = 0;
      }
      $loop = $loop + 1;
    }
  }

  $. = 0;    # remet le compteur de ligne a zero
  close DATA_FILE;
}

if ( defined $xml ) {
  print $tsg_xml_hdl "  </DATA>\n</OCEANO>\n";
}

