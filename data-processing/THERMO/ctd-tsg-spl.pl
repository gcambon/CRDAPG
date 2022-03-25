#!/usr/bin/perl -w
#
# extraction des temperature/salinite CTD de 0 a 5m pour generer
# un fichier .spl au format tsgqc et comparaison avec le TSG
#
# J Grelet IRD fevrier 2004 - avril 2015 PIRATA-FR25
# modifie le 18 nov 2010 pour mettre au format tsgqc
# modifie le 14 fev 2014 pour mettre au format .spl
# modifie le 08 avr 2015 pour utiliser le fichier config.ini
#
# $Id$

use strict;    # necessite de declarer toutes les variables globales

#use diagnostics;

use Time::Local;
use Date::Manip;
use File::Basename;
use Data::Dumper;
use Getopt::Long;
use Switch;
use Oceano::Seawater;
use Config::Tiny;

#------------------------------------------------------------------------------
# Les repertoires de sorties
#------------------------------------------------------------------------------
my $ascii_dir = 'ascii/';
my $tsgqc_dir = 'tsgqc/';

#------------------------------------------------------------------------------
# Les variables globales
#------------------------------------------------------------------------------
our $VERSION = '1.0';
my $debug;
my $echo;
my $dtd = 'public';
my $dtdLocalPath;
my $encoding;

# a mettre sous forme d'argument ligne de commande
my $author;
my $cycle_mesure;
my $plateforme;
my $institute;
my $pi;
my $creator;
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
my $tsgFile;

# profondeur de la prise d'eau
my $depth_intake = 4;
my $pressure_max;

my $version;
my $help;
my $xml   = undef;
my $ascii = 1;

my $code = -1;    # code pour l'entete

my $hdr_file;
my $hdr_file_dec;
my $spl_file;
my $tsgType;
my $ctdType;
my $tsgSn;
my $ctdSn;

my ($seasave_version) = undef;
my (
  $station, $depth, $pres,      $T0,     $T1,  $FlC,
  $Xmiss,   $Par,   $Spar,      $Ox0,    $Ox1, $nbin,
  $S0,      $S1,    $sigmateta, $sndvel, $trans
);
my ( $TempCTD, $SalCTD, $CondCTD, $CondTSG );
my ( $year, $lat, $lat_dec, $lat_deg, $lat_min, $lat_hemi );
my ( $long, $long_dec, $long_deg, $long_min, $long_hemi );
my ( $julien, $h_date, $date, $mois, $jour, $annee, $heure, $min, $sec, $time );
my ( $dateTSG, $heureTSG, $SSJT, $SalTSG, $TempTSG, $scan );
my $TempCTD_QC = 0;
my $SalCTD_QC  = 0;
my $flag       = 0;

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
  print STDERR "\nusage: ctd-tsg-spl.pl [options] <files>\n\n";
  print STDERR
    "Options:\n    --help                 Display this help message\n";
  print STDERR "    --version              program version\n";
  print STDERR "    --echo                 display filenames processed\n";
  print STDERR "    --cycle_mesure=<name>  cycle_mesure name\n";
  print STDERR "    --plateforme=<ship_name>     ship name\n";
  print STDERR
    "    --depth_intake=4       depth intake for salinity, 4 m by default\n";
  print STDERR "\naccept short options like -d1 -t2\n\n";
  print STDERR
"example:\n\$ perl ctd-tsg-spl.pl ../CTD/data/asc/$cruisePrefix*.hdr --echo\n";
  exit 1;
}

#------------------------------------------------------------------------------
# get_options()
# analyse les options
#------------------------------------------------------------------------------
sub get_options() {

  &GetOptions(
    "cycle_mesure=s" => \$cycle_mesure,
    "plateforme=s"   => \$plateforme,
    "depth_intake=i" => \$depth_intake,
    "echo"           => \$echo,
    "version"        => \$version,
    "help"           => \$help
  ) or &usage;

  &version if $version;
  &usage   if $help;
  $xml = undef if $ascii;
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
  my $tmp = $min;
  $min = abs $tmp;
  my $sec = ( $tmp - $min ) * 100;
  return ( ( $deg + ( $min + $sec / 100 ) / 60 ) * $sign );
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub julian {
  my ( $jj, $h, $m ) = @_;
  my $tmp = ( ( $h * 60 ) + $m ) / 1440;
  return ( $jj + $tmp );
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
  $begin_date   = &read_config_string( $Config, 'cruise', 'begin_date' );
  $end_date     = &read_config_string( $Config, 'cruise', 'end_date' );
  $institute    = &read_config_string( $Config, 'cruise', 'institute' );
  $pi           = &read_config_string( $Config, 'cruise', 'pi' );
  $creator      = &read_config_string( $Config, 'cruise', 'creator' );
  $cruisePrefix = &read_config_string( $Config, 'thermo', 'cruisePrefix' );
  $stationPrefixLength =
    &read_config_string( $Config, 'ctd', 'stationPrefixLength' );
  $depth_intake  = &read_config_string( $Config, 'thermo', 'depth_intake' );
  $tsgType       = &read_config_string( $Config, 'thermo', 'type' );
  $ctdType       = &read_config_string( $Config, 'ctd',    'type' );
  $tsgSn         = &read_config_string( $Config, 'thermo', 'sn' );
  $ctdSn         = &read_config_string( $Config, 'ctd',    'sn' );
  $title_summary = &read_config_string( $Config, 'thermo', 'title_summary' );
  $comment       = &read_config_string( $Config, 'thermo', 'comment' );
}

#------------------------------------------------------------------------------
# Debut du programme principal
#------------------------------------------------------------------------------
#&Date_Init( "TZ=UTC" );  # the TZ Date::Manip config variable is deprecated
&Date_Init("SetDate=now,UTC");
&read_config('../config.ini');
&usage if ( $#ARGV == -1 );
&get_options;

$tsgFile = $ascii_dir . $cycle_mesure . '.tsg';
mkdir($ascii_dir) unless ( -d $ascii_dir );
open( TSG_FILE, $tsgFile ) or warn( "\n" . $tsgFile . ": " . $! );

# lecture du premier fichier d'entete pour extraction des parametres
# generaux si ces derniers n'ont pas ete definit sur la ligne de commande.
open( DATA_FILE, $ARGV[0] );
while (<DATA_FILE>) {    # header contient l'entete
  if (/Ship\s*:\s*(.*)/) {
    if ( not defined $plateforme ) {
      ($plateforme) = $1;
      chop $plateforme;    # enleve le dernier caractere \n car motif (.*)
    }
  }
  if (/Cruise\s*:\s*(\S+)/) {
    ($cycle_mesure) = $1 if ( not defined $cycle_mesure );
  }
  if (/Sea-Bird\s+(\w+\s+\d+)/) {
    ($ctdType) = $1 if ( not defined $ctdType );
  }
  if (/Software Version Seasave V\s+(\d+\.\d+)/) {
    ($seasave_version) = $1 if ( not defined $seasave_version );
  }
}

# ouverture des fichiers de sortie, on met en minuscule, lower case
my $fileName = $ARGV[0];
my ( $name, $dir ) = fileparse $fileName;
$hdr_file     = lc $ascii_dir . $cycle_mesure . '-CTD-TSG.txt';
$hdr_file_dec = lc $ascii_dir . $cycle_mesure . '-CTD-TSG_txt';
$spl_file     = lc $tsgqc_dir . $cycle_mesure . '.spl';

# ouverture des fichiers resultants, on sort si erreur
open( HDR_FILE, "+> $hdr_file" ) or die "Can't open file : $hdr_file\n";
open( HDR_FILE_DEC, "+> $hdr_file_dec" )
  or die "Can't open file : $hdr_file_dec\n";
open( SPL_FILE, "+> $spl_file" ) or die "Can't open file : $spl_file\n";

# ecriture des entetes
print HDR_FILE "$cycle_mesure  $plateforme DEPTH_INTAKE=$depth_intake m\n";
print HDR_FILE
"St  Heure   Date    Latitude   Longitude  TempCTD  TempTSG  SalCTD  SalTSG   CondCTD CondTSG\n\n";
print HDR_FILE_DEC "$cycle_mesure  $plateforme DEPTH_INTAKE=$depth_intake m\n";
print HDR_FILE_DEC
"St  Annee Jour_julien   Latitude   Longitude  TempCTD  TempTSG  SalCTD  SalTSG   CondCTD CondTSG\n\n";
print SPL_FILE "%PLATFORM_NAME $plateforme\n";
print SPL_FILE "%CYCLE_MESURE $cycle_mesure\n";
print SPL_FILE "%DEPTH_INTAKE $depth_intake\n";
print SPL_FILE
"%HEADER YEAR MNTH DAYX hh mi ss LATX_EXT LONX_EXT SSPS_EXT SSPS_EXT_QC SSPS_EXT_TYPE SSTP_EXT SSTP_EXT_QC SSTP_EXT_TYPE\n";
close DATA_FILE;

# parcourt des fichiers .HDR et .asc
for ( my $i = 0 ; $i <= $#ARGV ; $i++ ) {
  my $fileName = $ARGV[$i];

  # recupere le numero de la station dans le nom du fichier
  if ( $fileName =~ /.+$cruisePrefix(\d{$stationPrefixLength})/ ) {
    $station = $1;
    open( DATA_FILE, $fileName ) or warn( "\n" . $fileName . ": " . $! );
    print STDERR "Lit: $fileName" if defined $echo;

    # on lit les fichiers d'extention .hdr contenant les entetes
    while (<DATA_FILE>) {
      if (/System UpLoad Time =\s+(\.*)/) {    # a modifier suivant le contexte
        ($time) = /System UpLoad Time =\s+(\w+\s+\d+\s+\d+\s+\d+:\d+:\d+)/;
        $date = &ParseDate($time);

        # transforme le day_of_year en julian day
        $julien = &UnixDate( $time, "%j" ) - 1;
        $julien =
          &julian( $julien, &UnixDate( $date, "%H" ),
          &UnixDate( $date, "%M" ) );
        $year   = &UnixDate( $time, "%Y" );
        $h_date = &UnixDate( $date, "%H:%M %d/%m/%Y" );
        ( $annee, $mois, $jour, $heure, $min, $sec ) =
          &Date_NthDayOfYear( $year, $julien + 1 );
      }

      if (/NMEA Latitude\s*=\s*(\d+\s+\d+.\d+\s+\w)/) {
        ( $lat_deg, $lat_min, $lat_hemi ) = split " ", $1;
        $lat_dec = &position( $lat_deg, $lat_min, $lat_hemi );
      }
      if (/NMEA Longitude\s*=\s*(\d+\s+\d+.\d+\s+\w)/) {
        ( $long_deg, $long_min, $long_hemi ) = split " ", $1;
        $long_dec = &position( $long_deg, $long_min, $long_hemi );
      }
    }

    $SSJT = $SalTSG = $TempTSG = 0;
    &Date_Init( "DateFormat=non-US", "SetDate=now,UTC" );
    my $line           = 0;
    my $skipHeaderLine = 2;
    while (<TSG_FILE>) {
      $line++;
      if ( $line <= $skipHeaderLine ) {

        #print STDERR "Line: $line\n";
        next;
      }
      else {
        (
          undef, $dateTSG, $heureTSG, undef,    undef, undef,
          undef, $SSJT,    $SalTSG,   $CondTSG, $TempTSG
        ) = split;

        #print STDERR "$SSJT $SalTSG $CondTSG $TempTSG\n";
        $dateTSG = &ParseDate( $dateTSG . " " . $heureTSG );

        #printf STDERR "%s %s\n", &UnixDate($dateTSG,"%d/%m/%Y %H:%M:%S"),
        #                         &UnixDate($date,"%d/%m/%Y %H:%M:%S");
        $flag = &Date_Cmp( $dateTSG, $date );
        if ( $flag == 0 ) {

          #print "\n$_\n";
          last;    # last is like break in C
        }
        elsif ( $flag > 0 ) {

          #print "\n$_\n";
          last;
        }
        else {
          $SSJT = $SalTSG = $TempTSG = 0;
        }
      }
    }
    &Date_Init( "DateFormat=US", "SetDate=now,UTC" );

    # affiche l'entete station a l'ecran
    printf STDERR " %05d %s %02d %05.2f %s %03d %05.2f %s", $station,
      $h_date, $lat_deg, $lat_min, $lat_hemi, $long_deg, $long_min, $long_hemi
      if defined $echo;
    close DATA_FILE;

    # on lit les fichiers d'extension .asc contenant les donnees
    # attention aux majuscules/minuscules !!!!!
    $fileName =~ s/\.hdr/\.asc/i;

    #print STDERR  "Lit: $fileName" if defined $echo;
    # si fichier ouvert, on lit, sinon, on affiche une erreur sur STDERR

    # for each file, reset pressure_max to 0
    $pressure_max = 0;
    $TempCTD = 0;
    $SalCTD  = 0;

    if ( open( DATA_FILE, $fileName ) ) {
      while (<DATA_FILE>) {

        # on expurge toutes les lignes des entetes ainsi que les lignes vides
        # n'est pas necessaire avec asciiout
        if ( not( /^[*#]/ || /^\s*$/ ) ) {
          (
            $scan,    undef, $pres, $depth, $T0,   $T1,
            $CondCTD, undef, undef, undef,  undef, undef,
            undef,    undef, undef, undef,  undef, $S0,   $S1,
            undef,    undef, undef, undef,  $nbin
          ) = split;
          next if ( $scan eq 'Scan' );

          # if pressure decrease, go to next line
          if ( $pres > $pressure_max ) {
            $pressure_max = $pres;
            if ( $pres == $depth_intake ) {
              $TempCTD = $T0;
              $SalCTD  = $S0;
              #printf STDERR "Valeur: %6.3f  %6.3f", $TempCTD,
	      #$SalCTD;
            }
          }
          else {
            next;
          }

=pod
  	  if ($station == 203) { # pd de pompe (meduse)
  	    printf STDERR "\n%5d use secondary %d db\n", $station, $pres;
              $TempCTD = $T1; $SalCTD = $S1;
            } else {
              $TempCTD = $T0; $SalCTD  = $S0;
            }  
=cut

        }
      }

      # ecriture dans le fichier
      printf HDR_FILE
"%05d %s %02d %05.2f %s %03d %05.2f %s %6.3f  %6.3f  %6.3f  %6.3f  %6.4f  %6.4f\n",
        $station, $h_date, $lat_deg, $lat_min, $lat_hemi, $long_deg,
        $long_min,
        $long_hemi, $TempCTD, $TempTSG, $SalCTD, $SalTSG, $CondCTD,
        $CondTSG;
      printf HDR_FILE_DEC
"%05d %4d %10.9g %+08.4f %+09.4f %6.3f  %6.3f  %6.3f  %6.3f  %6.4f  %6.4f\n",
        $station, $year, $julien, $lat_dec, $long_dec, $TempCTD,
        $TempTSG, $SalCTD, $SalTSG,, $CondCTD, $CondTSG;
      printf STDERR " %6.3f  %6.3f  %6.3f  %6.3f\n", $TempCTD, $TempTSG,
        $SalCTD, $SalTSG;
      printf SPL_FILE
"%04d %02d %02d %02d %02d %02d   %+10.7f   %+11.7f %6.3f %d CTD %6.3f %d CTD\n",
        $annee, $mois, $jour, $heure, $min, $sec, $lat_dec, $long_dec,
        $SalCTD, $SalCTD_QC, $TempCTD, $TempCTD_QC;
    }
    else {
      warn( "\nErr: " . $fileName . ": " . $! );
    }
    $pres = 1e36;
    $.    = 0;      # remet le compteur de ligne a zero
  }
  close DATA_FILE;
}

# return result for matlab

close HDR_FILE;
close HDR_FILE_DEC;
