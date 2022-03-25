##!/usr/bin/perl -w
#
# xbt-edf.pl  Traitement des fichiers XBT Sippican.  
# Utilise les fichiers d'extensions .EDF
# Cette version 1.1 genere les 3 fichiers d'extentions .hdr, _xbt et _xbt.xml par defaut
#  
# $Id$
#

use strict;

use Time::Local;
use File::Basename;
use Data::Dumper;
use Getopt::Long;
use Oceano::Seawater;
use Oceano::Convert;
use Oceano::Seabird;
use Cwd;
use Config::Tiny;

#------------------------------------------------------------------------------
# Les repertoires de sorties
#------------------------------------------------------------------------------
my $ascii_dir = 'ascii/';
my $odv_dir   = 'odv/';

#------------------------------------------------------------------------------
# Les variables globales
#------------------------------------------------------------------------------
our $VERSION = '1.0';
my $author;
my  $debug;
my  $echo;
my  $dtd = 'public';
my  $dtdLocalPath;
my  $encoding;

# surcharge par la valeurs saisies sur la ligne de commande
my  $version;
my  $help;

my  $institute;
my  $type;
my  $sn;
my  $pi;
my  $creator;
my  $acquisitionSoftware;
my  $acquisitionVersion;
my  $processingSoftware;
my  $processingVersion;

#my  $software         = "WinMK21";
#my  $software_version = "V2.6.1";
#my  $type             = "MK-21";  
#my  $sn               = "0054";
#my  $validation_comment = "Extraction réalisée sur fichier .edf, visualisee avec datagui";

my  $cycle_mesure;
my  $plateforme;
my  $context;
my  $timezone;
my  $format_date;
my  $processing_code;
my  $begin_date;
my  $end_date;
my  $cruisePrefix;
my  $stationPrefixLength;
my  $title_summary;
my  $comment;
my  $header;
my  @header;
my  $split;
my  %split;
my  $format;
my  @format;
my  %format;
my  %data;
my  @data;
my  ($odv_hdr,$odv_unit);
my  (@odv_hdr, @odv_unit);
my  %odv_hdr;
my  $PRFL;

my  $xml           = undef;       # par defaut, sortie XML activee
my  $ascii         = undef;   
my  $odv           = undef;   
my  $all           = undef;   

my  $code          = -1;      # code pour l'entete
my  $S             = 35;
my  $C;
my  $hdr_file;
my  $ascii_file;
my  $xml_file;
my  $odv_hdr_file;
my  $odv_file;
my  $type_odv = "C" ;
my  $bottom_depth = 0;
my  %file;
my  $key;

my ($cycle_mesure, $plateforme, $probe) = undef;
my ($profil, $depth, $T, $sigmateta, $sndvel);
my ($lat, $lat_pos, $lat_deg, $lat_min, $lat_hemi);
my ($long, $long_pos, $long_deg, $long_min, $long_hemi);
my ($julien, $date_FR);
my $year_ref = undef;
# mettre a jour le decodage des entete ASAP
my ($dummy,$dpth);

#------------------------------------------------------------------------------
# version()
#------------------------------------------------------------------------------	
sub version() {
  print "Version: $VERSION\nAuthor: $author\n\n";	
  exit 1;
}	

#------------------------------------------------------------------------------
# usage()
#------------------------------------------------------------------------------	
sub usage() {
  print STDERR "\nusage: xbt-edf.pl [options] <rep/files>\n\n";
  print STDERR   "Options:\n    --help                 Display this help message\n";
  print STDERR   "    --version              program version\n";
  print STDERR   "    --debug=[1-3]          debug info\n";
  print STDERR   "    --echo                 display filenames processed\n";
  print STDERR   "    --cycle_mesure=<name>  give cruise name\n";
  print STDERR   "    --plateforme=<name>    ship or plateforme name\n";
  print STDERR   "    --begin_date=JJ/MM/YYYY   starting date from cycle_mesure\n";
  print STDERR   "    --end_date  =JJ/MM/YYYY   end date from cycle_mesure\n";

  print STDERR   "    --institute=<name>     institute name\n";
  print STDERR   "    --code_oopc=<value>    processing code\n";
  print STDERR   "    --pi=<pi_name> \n";
  print STDERR   "    --output=<file_name>   filename without extension\n";
  print STDERR   "    --dtd=[local|public]   define DTD, default public\n";
  print STDERR   "    --type=<instrument_type> \n";
  print STDERR   "    --sn=<instrument_serial_number> \n";
  print STDERR   "    --software=<software_name> \n";
  print STDERR   "    --software_version=<software_version> \n";
  print STDERR   "    --xml                  only XML output (default)\n";
  print STDERR   "    --ascii                only ASCII output\n";
  print STDERR   "    --odv                  only ODV output\n";
  print STDERR   "    --all                  ASCII,XML and ODV output\n";
  print STDERR   "\naccept short options like -d1 -t2\n\n";
  print STDERR   "XBT example:\n------------\n\$ perl xbt-edf.pl  --cycle_mesure=$cycle_mesure --institute=$institute --plateforme='$plateforme' --sn=$sn --type=$type --pi=$pi --begin_date=$begin_date --end_date=$end_date --echo --dtd=local data/*.EDF --all\n\n"; 
  exit 1;
}

#------------------------------------------------------------------------------
# get_options()
# analyse les options
#------------------------------------------------------------------------------	
sub get_options() {
  
  &GetOptions ("cycle_mesure=s"     => \$cycle_mesure,    
               "type=s"             => \$type,  
	       "sn=s"               => \$sn,
               "software=s"         => \$acquisitionSoftware,  
               "software_version=s" => \$acquisitionVersion,  
               "plateforme=s"       => \$plateforme,  
               "begin_date=s"       => \$begin_date,  
               "end_date=s"         => \$end_date,  	       
               "pi=s"               => \$pi,
               "code_oopc=s"        => \$processing_code,  
               "ascii"              => \$ascii,  
               "xml"                => \$xml,  
               "odv"                => \$odv,	 
               "all"                => \$all,	 
               "debug=i"            => \$debug,  
               "echo"               => \$echo,  
               "institute=s"        => \$institute,  
               "dtd=s"              => \$dtd,  
               "version"            => \$version,  
               "help"               => \$help)  or &usage;  
       
  &version if $version;	
  &usage   if $help;	

  # xml by default
  $xml = 1 if (!defined $ascii && !defined $odv); 
  if ($all) { $ascii = $odv = $xml = 1; }
}

=pod
#------------------------------------------------------------------------------
# fonctions de calcul de la position/date
#------------------------------------------------------------------------------
sub position {
  my($deg,$min,$hemi)=@_;
  my $sign = 1;
  if( $hemi eq "S" || $hemi eq "W") {
    $sign = -1;
  }
  my $tmp = $min;
  $min = abs $tmp;
  my $sec = ($tmp - $min ) * 100;
  return( ( $deg + ( $min + $sec / 100 ) / 60 ) * $sign ); 
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub julian {
  my($jj,$h,$m)=@_;
  my $tmp = (($h * 60) + $m ) / 1440;
  return( $jj + $tmp ); 
}
=cut

#------------------------------------------------------------------------------
# entete XML
#------------------------------------------------------------------------------
sub entete_xml { 
  my $today = &dateFormat("now", "%d/%m/%Y");
  
  print  XML_FILE "<?xml version=\"1.0\" encoding=\"$encoding\"?>\n"; 
  # les commentaires ne sont pas acceptés par XML Toolbox Matlab de Geodise
  if ( $dtd eq 'local' ) {
    print  XML_FILE "<!DOCTYPE OCEANO SYSTEM \"$dtdLocalPath/local/oceano.dtd\">\n";
  } else {  
    print  XML_FILE '<!DOCTYPE OCEANO PUBLIC "-//US191//DTD OCEANO//FR" "http://www.brest.ird.fr/us191/database/oceano.dtd">' . "\n";
  }
  print  XML_FILE '<OCEANO TYPE="PROFIL">' . "\n";
  print  XML_FILE "  <ENTETE>\n";
  print  XML_FILE "    <PLATEFORME>\n";
  print  XML_FILE "      <LIBELLE>$plateforme</LIBELLE>\n";  
  print  XML_FILE "    </PLATEFORME>\n";
  print  XML_FILE "    <CYCLE_MESURE CONTEXTE=\"$context\" TIMEZONE=\"$timezone\" FORMAT=\"$format_date\">\n";  
  print  XML_FILE "      <LIBELLE>$cycle_mesure</LIBELLE>\n";  
  print  XML_FILE "      <DATE_DEBUT>$begin_date</DATE_DEBUT>\n";  
  print  XML_FILE "      <DATE_FIN>$end_date</DATE_FIN>\n";  
  print  XML_FILE "      <INSTITUT>$institute</INSTITUT>\n";  
  print  XML_FILE "      <RESPONSABLE>$pi</RESPONSABLE>\n"; 
  print  XML_FILE "      <ACQUISITION LOGICIEL=\"$acquisitionSoftware\" VERSION=\"$acquisitionVersion\"></ACQUISITION>\n"; 
  print  XML_FILE "      <TRAITEMENT LOGICIEL=\"$0\" VERSION=\"$VERSION\"></TRAITEMENT>\n"; 
  print  XML_FILE "      <VALIDATION LOGICIEL=\"datagui\" VERSION=\"1.0\" DATE=\"$today\" OPERATEUR=\"$pi\" CODIFICATION=\"OOPC\">\n";
  print  XML_FILE "        <CODE>$processing_code</CODE>\n";	    
  print  XML_FILE "        <COMMENTAIRE>$comment</COMMENTAIRE>\n";
  print  XML_FILE "        <COMMENTAIRE>$title_summary</COMMENTAIRE>\n";
  print  XML_FILE "      </VALIDATION>\n";  
  print  XML_FILE "    </CYCLE_MESURE>\n";  
  print  XML_FILE "    <INSTRUMENT TYPE=\"$type\" NUMERO_SERIE=\"$sn\">\n"; 
  print  XML_FILE "    </INSTRUMENT>\n";  
  print  XML_FILE "  </ENTETE>\n";  
  print  XML_FILE "  <DATA>\n";  
}

#------------------------------------------------------------------------------
# entete ODV
#------------------------------------------------------------------------------
sub entete_odv { 
  my $today = &dateFormat(undef,"%d/%m/%Y");
  my $cwd = getcwd();

  print  ODV_FILE "//ODV Spreadsheet file : $odv_file\n"; 
  print  ODV_FILE "//Data treated : $today\n"; 
  print  ODV_FILE "//<DataType>Profiles</DataType>\n";
  print  ODV_FILE "//<InstrumentType>$type</InstrumentType>\n";
  print  ODV_FILE "//<Source>$cwd</Sources>\n"; 
  print  ODV_FILE "//<Creator>$creator</Creator>\n";    
  print  ODV_FILE "//\n"; 
  print  ODV_FILE "Cruise\tStation\tType\tyyyy-mm-ddThh:mm:ss\Longitude [degrees_east]\tLatitude [degrees_north]\tBot. Depth [m]\tDepth [m]\tTEMP [C]\tPSAL [Psu]\tDENS [kg/m3]\tSVEL [m/s]\n"; 
}

#------------------------------------------------------------------------------
# read string key inside section in config file
#------------------------------------------------------------------------------	
sub read_config_string() {
  my ($Config, $section, $key) = @_;

  my $value = $Config->{$section}->{$key};
  if (!defined $value ) {die "Missing string '$key' in section '$section' $!";}
  return $value;
}

#------------------------------------------------------------------------------
# read config.ini file where cruise parameter are defined 
#------------------------------------------------------------------------------	
sub read_config() {
  my ($configFile) = @_;

  # Create a config
  my $Config = Config::Tiny->new;
  
  $Config = Config::Tiny->read( $configFile ) 
	  or die "Could not open '$configFile' $!";

  $author             = &read_config_string( $Config, 'global', 'author');
  $debug              = &read_config_string( $Config, 'global', 'debug');
  $echo               = &read_config_string( $Config, 'global', 'echo');
  $dtd                = &read_config_string( $Config, 'xml',    'dtd');
  $dtdLocalPath       = &read_config_string( $Config, 'xml',    'dtdLocalPath');
  $encoding           = &read_config_string( $Config, 'xml',    'encoding');
  $cycle_mesure       = &read_config_string( $Config, 'cruise', 'cycle_mesure');
  $plateforme         = &read_config_string( $Config, 'cruise', 'plateforme');
  $context           = &read_config_string( $Config, 'cruise', 'context');
  $timezone           = &read_config_string( $Config, 'cruise', 'timezone');
  $format_date        = &read_config_string( $Config, 'cruise', 'format_date');
  $processing_code    = &read_config_string( $Config, 'cruise', 'processing_code');
  $begin_date         = &read_config_string( $Config, 'cruise', 'begin_date');
  $end_date           = &read_config_string( $Config, 'cruise', 'end_date');
  $institute           = &read_config_string( $Config, 'cruise', 'institute');
  $pi                 = &read_config_string( $Config, 'cruise', 'pi');
  $creator            = &read_config_string( $Config, 'cruise', 'creator');
  $acquisitionSoftware = &read_config_string( $Config, 'xbt', 'acquisitionSoftware');
  $acquisitionVersion = &read_config_string( $Config, 'xbt', 'acquisitionVersion');
  $processingSoftware = &read_config_string( $Config, 'xbt', 'processingSoftware');
  $processingVersion  = &read_config_string( $Config, 'xbt', 'processingVersion');
  $type            = &read_config_string( $Config, 'xbt',     'type');
  $sn              = &read_config_string( $Config, 'xbt',     'sn');
  $title_summary      = &read_config_string( $Config, 'xbt',     'title_summary');
  $comment            = &read_config_string( $Config, 'xbt',     'comment');
}

#------------------------------------------------------------------------------
# Debut du programme principal
#------------------------------------------------------------------------------
my ($d,$M,$Y,$h,$m,$s, $date_EN);

&dateInit( "EN","GMT" );
&read_config('../config.ini');
&usage if( $#ARGV == -1);
&get_options;

print STDERR "Output: ";
print STDERR "ASCII " if (defined $ascii);
print STDERR "XML "   if (defined $xml);
print STDERR "ODV "   if (defined $odv);

# lecture du premier fichier d'entete pour extraction des parametres
# generaux. On peut se contenter de les mettre a jour uniquement dans
# ce fichier
open( HEADER, $ARGV[0] );
while( <HEADER> ){           # header contient l'entete
  if( /Ship\s*:\s*(.*)/ or /Navio\s*:\s*(.*)/) {
    if ( not defined $plateforme ) {
      ($plateforme) = $1;
       chomp $plateforme;  # enleve le dernier caractere \n car motif (.*)
    }  
  }
  if( /Cruise\s*:\s*(\S+)/ or /Comissao\s*:\s*(\S+)/ ) {
    ($cycle_mesure) = $1 if ( not defined $cycle_mesure );
  }
}  
# nomme les fichiers
$hdr_file = lc $ascii_dir.$cycle_mesure.'.xbt';
$ascii_file = lc $ascii_dir.$cycle_mesure.'_xbt' if (defined $ascii);
$xml_file = lc $ascii_dir.$cycle_mesure.'_xbt.xml' if (defined $xml);
$odv_file = lc $odv_dir.$cycle_mesure.'_xbt_odv.txt' if (defined $odv);

if( $debug ) {
  printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n",
          $hdr_file,$ascii_file,$xml_file,$institute,$plateforme,$type,$sn,$pi;
  for( my $i = 0; $i <= $#ARGV; $i++ ){
    print $ARGV[$i] . "\n";
  }
  print "\nExit xbt-edf.pl ... debug mode\n";
  exit;
}
# ouverture des pointeurs (handles) de fichiers
if (defined $odv) {
  mkdir($odv_dir) unless(-d $odv_dir);
  open( ODV_FILE,   "+> $odv_file" )   or die "Can't open file : $odv_file\n";
  &entete_odv;
} 
if (defined $ascii) {
  mkdir($ascii_dir) unless(-d $ascii_dir);
  open( HDR_FILE,   "+> $hdr_file" )   or die "Can't open file : $hdr_file\n";
  open( ASCII_FILE, "+> $ascii_file" ) or die "Can't open file : $ascii_file\n";
}  
if (defined $xml) {
  mkdir($ascii_dir) unless(-d $ascii_dir);
  open( XML_FILE,   "+> $xml_file" )   or die "Can't open file : $xml_file\n";
}
# ecriture des entetes
if (defined $ascii) {
  print HDR_FILE "$cycle_mesure  $plateforme  $institute  $type  $sn  $pi\n";  
  print HDR_FILE "St   Date  Heure    Latitude   Longitude  Profondeur\n";
  print ASCII_FILE "$cycle_mesure  $plateforme  $institute  $type  $sn  $pi\n";  
  print ASCII_FILE "PRFL   DEPH   TEMP   PSAL    DENS    SVEL \n";
}
if (defined $xml) {
  &entete_xml; 
  print XML_FILE   "PRFL   DEPH   TEMP   PSAL    DENS    SVEL \n";
}
close HEADER;

# parcourt les fichiers et créé une table de hashage numero_tir => nom_fichier
foreach (@ARGV) {
  ($key) = /_+(\d+)/;
  $file{$key} = $_;
}

# tri le hash %file par numero_tir et parcourt le hash trié
foreach my $cle (sort { $a <=> $b } keys %file) { 
  open( DATA_FILE, $file{$cle} ) or warn("Erreur: " . $!);
  print STDERR  "\nLit: $file{$cle}" if defined $echo;
  while( <DATA_FILE> ){           # header contient l'entete
    ($profil) = $1 if (/Sequence Number\s+:\s+(\d+)/);
    if( /Probe Type\s+:\s+(.*)/)	{
      ($probe) = $1;
      chop $probe;
      $probe =~ tr/ /-/;
    }
    ($M,$d,$Y) = ($1,$2,$3) if (/Date of Launch\s+:\s+(\d+)\/(\d+)\/(\d+)/);
    $year_ref = $Y if (!defined $year_ref);
    if (/Time of Launch\s+:\s+(\d+):(\d+):(\d+)/)	{
      ($h,$m,$s) = ($1,$2,$3);	
      # transforme le day_of_year en julian day 0
      $julien = &date2julian($year_ref,$Y,$M,$d,$h,$m,$s);
      # a modifier absolument, verrue
      $date_FR = sprintf("%02d/%02d/%04d %02d:%02d", $d,$M,$Y,$h,$m); # pour fichier entete	      
      $date_EN = sprintf("%02d/%02d/%04d %02d:%02d", $M,$d,$Y,$h,$m); # pour fichier entete
    }
    if (/Latitude\s+:\s+(\d+)\s+(\d+\.\d+)(\w)/)	{
      ($lat_deg, $lat_min, $lat_hemi) = ($1,$2,$3);
      $lat_pos = &positionDeci($lat_deg, $lat_min, $lat_hemi);
    }
    if (/Longitude\s+:\s+(\d+)\s+(\d+\.\d+)(\w)/) {
      ($long_deg,$long_min,$long_hemi)= ($1,$2,$3); 
      $long_pos = &positionDeci($long_deg, $long_min, $long_hemi);
    }
    # detecte la fin de l'entete du fichier, a modifier eventuellement le test
    #if (/This (XBT|XCTD) export/) {  
    if (m[//\s+Data\r]) {  
      printf XML_FILE "%3d  %4d %7.3f %7.4f %8.4f %s\n",$profil, $code,$julien,
          $lat_pos, $long_pos,&dateFormat($date_EN) if (defined $xml);
      printf ASCII_FILE "%3d  %4d %7.3f %7.4f %8.4f %s\n",$profil, $code,$julien,
          $lat_pos, $long_pos,&dateFormat($date_EN) if (defined $ascii);
    }
    # lit les donnees et eclate la ligne, utilise la ligne courante $_ par defaut
    if (/^\d/) {
      if ($probe =~ /XCTD/) {	    
        ($depth,$T,$C,$S,$sndvel,$sigmateta) = split;
      }	
      else {	      
        (undef,undef,$depth,$T,$sndvel) = split;
        $S = 35; 
	# routine de calcul des parametres derives si necessaire, module seawater
        #$T68 = $T0 * 1.00024; 
        #$sndvel=&sw_svel($S,$T,$depth);
        $sigmateta = &sw_sigmateta($S,$T,$depth);
        $S  = 1e36; 
      }	
      if ($T > 1.0) {
	$dpth = $depth;  # memorise la profondeur max pour l'entete
	if (defined $xml) { 
          printf XML_FILE "%3d  %6.1f  %5.2f  %5.4g  %6.5g  %7.6g\n",
	      $profil, $depth, $T, $S, $sigmateta, $sndvel if (defined $xml);
        }
	if (defined $ascii) { 
      	  printf ASCII_FILE "%3d  %6.1f  %5.2f  %5.4g  %6.5g  %7.6g\n",
	      $profil, $depth, $T, $S, $sigmateta, $sndvel if (defined $ascii);
        }
        if (defined $odv) {
          printf ODV_FILE "%s\t%3d\t%s\t%s\t%8.4f\t%7.4f\t%6.1f\t%6.1f",
            $cycle_mesure, $profil, $type_odv, &dateFormat($date_EN,"%Y-%m-%dT%H:%M:%S"),
            $long_pos, $lat_pos, $bottom_depth, $depth;
	  printf ODV_FILE ($T > 1e35) ? "\t" : "\t%5.2f", $T;
          printf ODV_FILE ($S > 1e35) ? "\t" : "\t%5.2f", $S;
          printf ODV_FILE "\t%6.3f",   $sigmateta;
          printf ODV_FILE "\t%7.2f\n", $sndvel;
	}				
      }
    }
  }
  # ecriture de la ligne d'entete de chaque profil de le fichier .xbt 
  if (defined $ascii) { 
    printf HDR_FILE  "%3d %s %02d°%05.2f %s %03d°%05.2f %s %4.0f %s\n",
          $profil, $date_FR, $lat_deg, $lat_min, $lat_hemi, $long_deg, 
	  $long_min, $long_hemi, $dpth,$probe;
  }
  printf STDERR "   %3d %s %02d°%05.2f %s %03d°%05.2f %s %4.0f %s",
          $profil, $date_FR, $lat_deg, $lat_min, $lat_hemi, $long_deg, 
	  $long_min, $long_hemi, $dpth,$probe if defined $echo;
  $. = 0;
  close DATA_FILE;
}

# return output filename processed to matlab
#(!defined $xml) ? printf STDERR "$ascii_file\n" : printf STDERR "$xml_file\n";
printf STDERR "\n";;

# ferme les balises XML
if (defined $xml) {
  print  XML_FILE "  </DATA>\n";  
  print  XML_FILE "</OCEANO>\n";  
}  
# fermeture des pointeurs de fichiers
close HDR_FILE  if defined $ascii;
close XML_FILE  if defined $xml;
close ODV_FILE  if defined $odv;

