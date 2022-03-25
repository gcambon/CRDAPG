#!c:\perl\bin\perl -w
#
# Traitement des fichiers LADCP issus de la chaine LDEO Visbeck 
# Utilise les fichiers d'extensions .lad 
# J Grelet IRD  juin 2006 - maj PIRATA-FR26 mars 2015 
# 
# $Id$ 

use strict; # necessite de declarer toutes les variables globales
#use diagnostics;

# bug: Name "PDL::SHARE" used only once: possible typo at /usr/lib/perl/5.10/DynaLoader.pm line 216.
# see: http://www.digipedia.pl/usenet/thread/14593/3943/
# The other thing we could do (equally tedious) is to ensure that $PDL::SHARE
# is mentioned more than once by placing, in every test script, something
# like:
if(defined($PDL::SHARE)){}

use Time::Local;
use Date::Manip;
use File::Basename;
use Data::Dumper;
use Getopt::Long;
use Switch;
use Oceano::Seawater;
use PDL;
use PDL::Math;
use Cwd;
use Config::Tiny;

#------------------------------------------------------------------------------
# Les repertoires de sorties
#------------------------------------------------------------------------------
my $ascii_dir = 'ascii/';

#------------------------------------------------------------------------------
# Les variables globales
#------------------------------------------------------------------------------
our $VERSION = '1.0';
my  $author;
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

my $code           = -1;  # code pour l'entete

my  $xml           = 1;       # par defaut, sortie XML activee
my  $ascii         = undef;   
my  $odv           = undef;   
my  $all           = undef;   

my $ladcp_file;
my $hdr_file;

my($profil, $depth,$U,$V,$ev);
my($lat, $lat_deg, $lat_min, $lat_sec, $lat_hemi);
my($long, $long_deg, $long_min, $long_sec, $long_hemi);
my($julien, $h_date, $date, $time);
my $entete = 1;

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
  print STDERR "\nusage: perl ldeo-ladcp.pl [options] <files>\n\n";
  print STDERR   "Options:\n    --help                 Display this help message\n";
  print STDERR   "    --version              program version\n";
  print STDERR   "    --debug=[1-3]          debug info\n";
  print STDERR   "    --echo                 display filenames processed\n";
  print STDERR   "    --cycle_mesure=<name>  cycle_mesure name\n";
  print STDERR   "    --plateforme=<name>    ship or plateforme name\n";
  print STDERR   "    --begin_date=JJ/MM/YYYY     starting date from cycle_mesure\n";
  print STDERR   "    --end_date  =JJ/MM/YYYY     end date from cycle_mesure\n";

  print STDERR   "    --institute=<name>     institute name\n";
  print STDERR   "    --code_oopc=<value>    processing code\n";
  print STDERR   "    --pi=<pi_name> \n";
  print STDERR   "    --ascii                ASCII output instead XML\n";
  print STDERR   "    --xml                  XML output (default)\n";
  print STDERR   "    --dtd=[local|public]   define DTD, default public\n";
  print STDERR   "    --sn=<serial_number>\n";
  print STDERR   "    --type=<instrument_type> \n";
  print STDERR   "\naccept short options like -d1 -t2\n\n";
  print STDERR   "example:\n\$  perl ldeo-ladcp.pl  --cycle_mesure=$cycle_mesure --institute=$institute --plateforme='$plateforme' --sn=$sn --type=$type --pi=$pi --begin_date=$begin_date --end_date=$end_date --echo --dtd=local v10.16.2/$cycle_mesure/profiles/$cruisePrefix*.lad --xml\n"; 
  exit 1;
}

#------------------------------------------------------------------------------
# get_options()
# analyse les options
#------------------------------------------------------------------------------	
sub get_options() {
  
  &GetOptions ("cycle_mesure=s"  => \$cycle_mesure,    
               "plateforme=s"    => \$plateforme,  
               "begin_date=s"    => \$begin_date,  
               "end_date=s"      => \$end_date,  
               "pi=s"            => \$pi,  
               "type=s"          => \$type,  
               "sn=s"            => \$sn,  
               "code_oopc=s"     => \$processing_code,  	       
               "ascii"           => \$ascii, 
               "xml"             => \$xml,  
               "debug=i"         => \$debug,  
               "echo"            => \$echo,  
               "dtd=s"           => \$dtd,  
               "institute=s"     => \$institute,  
               "version"         => \$version,  
               "help"            => \$help)  or &usage;  
       
  &version if $version;	
  &usage   if $help;
  $ascii = undef if $xml;    
}

#------------------------------------------------------------------------------
# fonctions de calcul de la position/date
#------------------------------------------------------------------------------
sub position {
  my($deg,$min,$hemi) = @_;
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
  my($jj,$h,$m,$s)=@_;
  #print "$jj $h $m $s\n";
  my $tmp = ( ($h * 3600) + ( $m * 60 ) +$s ) / (1440 * 60);
  return( $jj + $tmp ); 
}

#------------------------------------------------------------------------------
# Conversion d'une heure ou position exprime en decimal en sexagesimal
#------------------------------------------------------------------------------
sub HtoHMS {
  my( $h1,$hemi ) = @_;

  my( $Sign,$h,$m1,$mi,$s);
  if ( $hemi eq 'lat') {
    if ( $h1 < 0 ) {
      $Sign = 'S';
    } else {
      $Sign = 'N';
    }
  } elsif( $hemi eq 'long' ) {
    if ( $h1 < 0 ) {
      $Sign = 'W';
    } else {
      $Sign = 'E';
    }   
  } 
  $h = $h1 < 0 ? ceil( $h1 ) : floor( $h1 );
  $m1 = ($h1 - $h) * 60;

  $mi = $m1 < 0 ? ceil( $m1 ) : floor( $m1 );
  $s = ($m1 - $mi) * 60;
  return( abs($h), abs($mi), abs($s), $Sign );
}   

#------------------------------------------------------------------------------
# entete XML
#------------------------------------------------------------------------------
sub entete_xml { 
  my($fileName) = @_;
  my $today = &UnixDate( &ParseDate("today"), "%d/%m/%Y");
  
   print  LADCP_FILE '<?xml version="1.0" encoding="ISO-8859-1"?>' . "\n"; 
  # les commentaires ne sont pas acceptés par XML Toolbox Matlab de Geodise
  if ( $dtd eq 'local' ) {
    print  LADCP_FILE "<!DOCTYPE OCEANO SYSTEM \"$dtdLocalPath/local/oceano.dtd\">\n";
  } else {  
    print  LADCP_FILE '<!DOCTYPE OCEANO PUBLIC "-//US191//DTD OCEANO//FR" "http://www.brest.ird.fr/us191/database/oceano.dtd">' . "\n";
  }
  print  LADCP_FILE '<OCEANO TYPE="PROFIL">' . "\n";
  print  LADCP_FILE "  <ENTETE>\n";
  print  LADCP_FILE "    <PLATEFORME>\n";
  print  LADCP_FILE "      <LIBELLE>$plateforme</LIBELLE>\n";  
  print  LADCP_FILE "    </PLATEFORME>\n";
  print  LADCP_FILE "    <CYCLE_MESURE CONTEXTE=\"$context\" TIMEZONE=\"$timezone\" FORMAT=\"$format_date\">\n";  
  print  LADCP_FILE "      <LIBELLE>$cycle_mesure</LIBELLE>\n";  
  print  LADCP_FILE "      <DATE_DEBUT>$begin_date</DATE_DEBUT>\n";  
  print  LADCP_FILE "      <DATE_FIN>$end_date</DATE_FIN>\n";  
  print  LADCP_FILE "      <INSTITUT>$institute</INSTITUT>\n";  
  print  LADCP_FILE "      <RESPONSABLE>$pi</RESPONSABLE>\n"; 
  print  LADCP_FILE "      <ACQUISITION LOGICIEL=\"$acquisitionSoftware\" VERSION=\"$acquisitionVersion\"></ACQUISITION>\n"; 
  print  LADCP_FILE "      <TRAITEMENT LOGICIEL=\"$0\" VERSION=\"$VERSION\"></TRAITEMENT>\n"; 
  print  LADCP_FILE "      <VALIDATION LOGICIEL=\"datagui\" VERSION=\"1.0\" DATE=\"$today\" OPERATEUR=\"$pi\" CODIFICATION=\"OOPC\">\n";
  print  LADCP_FILE "        <CODE>$processing_code</CODE>\n";	    
  print  LADCP_FILE "        <COMMENTAIRE>$comment</COMMENTAIRE>\n";
  print  LADCP_FILE "        <COMMENTAIRE>$title_summary</COMMENTAIRE>\n";
  print  LADCP_FILE "      </VALIDATION>\n";  
  print  LADCP_FILE "    </CYCLE_MESURE>\n";  
  print  LADCP_FILE "    <INSTRUMENT TYPE=\"$type\" NUMERO_SERIE=\"$sn\">\n"; 
  print  LADCP_FILE "    </INSTRUMENT>\n";  
  print  LADCP_FILE "  </ENTETE>\n";  
  print  LADCP_FILE "  <DATA>\n";  
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

  $author              = &read_config_string( $Config, 'global', 'author');
  $debug               = &read_config_string( $Config, 'global', 'debug');
  $echo                = &read_config_string( $Config, 'global', 'echo');
  $dtd                 = &read_config_string( $Config, 'xml',    'dtd');
  $dtdLocalPath        = &read_config_string( $Config, 'xml',    'dtdLocalPath');
  $encoding            = &read_config_string( $Config, 'xml',    'encoding');
  $cycle_mesure        = &read_config_string( $Config, 'cruise', 'cycle_mesure');
  $plateforme          = &read_config_string( $Config, 'cruise', 'plateforme');
  $context             = &read_config_string( $Config, 'cruise', 'context');
  $timezone            = &read_config_string( $Config, 'cruise', 'timezone');
  $format_date         = &read_config_string( $Config, 'cruise', 'format_date');
  $processing_code     = &read_config_string( $Config, 'cruise', 'processing_code');
  $begin_date          = &read_config_string( $Config, 'cruise', 'begin_date');
  $end_date            = &read_config_string( $Config, 'cruise', 'end_date');
  $institute           = &read_config_string( $Config, 'cruise', 'institute');
  $pi                  = &read_config_string( $Config, 'cruise', 'pi');
  $creator             = &read_config_string( $Config, 'cruise', 'creator');
  $cruisePrefix        = &read_config_string( $Config, 'ladcp', 'cruisePrefix');
  $stationPrefixLength = &read_config_string( $Config, 'ladcp', 'stationPrefixLength');
  $acquisitionSoftware = &read_config_string( $Config, 'ladcp', 'acquisitionSoftware');
  $acquisitionVersion  = &read_config_string( $Config, 'ladcp', 'acquisitionVersion');
  $processingSoftware  = &read_config_string( $Config, 'ladcp', 'processingSoftware');
  $processingVersion   = &read_config_string( $Config, 'ladcp', 'processingVersion');
  $type                = &read_config_string( $Config, 'ladcp',     'type');
  $sn                  = &read_config_string( $Config, 'ladcp',     'sn');
  $title_summary       = &read_config_string( $Config, 'ladcp',     'title_summary');
  $comment             = &read_config_string( $Config, 'ladcp',     'comment');
}

#------------------------------------------------------------------------------
# Debut du programme principal
#------------------------------------------------------------------------------
#&Date_Init( "TZ=UTC" );
&Date_Init( 'SetDate=now,UTC');
#&Date_Init( "TZ=UTC","Language=French","DateFormat=non-US" );
&read_config('../config.ini');
&usage if( $#ARGV == -1);
&get_options;

# ouverture des fichiers de sortie, on met en minuscule, lower case
my $fileName =  $ARGV[0];
my ($name,$dir) =  fileparse $fileName;
$ladcp_file = lc $ascii_dir.$cycle_mesure.'_adcp';
$ladcp_file .= '.xml' if defined $xml;
$hdr_file = lc  $ascii_dir.$cycle_mesure.'.adcp';

# ouverture des fichiers resultants, on sort si erreur
mkdir($ascii_dir) unless(-d $ascii_dir);
open( LADCP_FILE, "+> $ladcp_file" ) or die "Can't open file : $ladcp_file\n";
open( HDR_FILE, "+> $hdr_file" ) or die "Can't open file : $hdr_file\n";

# ecriture des entetes
if ( defined $xml ) {
  &entete_xml( $fileName );
} else {	
  print LADCP_FILE "$cycle_mesure  $plateforme  $institute  $type  $sn  $pi\n";
}

# EWCT;CURRENT EAST COMPONENT;meter/second;-100;100;%+7.3lf;-99.999
# NSCT;CURRENT NORTH COMPONENT;meter/second;-100;100;%+7.3lf;-99.999
 
print LADCP_FILE "PRFL    DEPH   EWCT    NSCT     N/A     N/A\n";
print HDR_FILE "$cycle_mesure  $plateforme  $institute  $type  $sn  $pi\n";
print HDR_FILE   "St   Date    Heure  Latitude   Longitude  Profondeur\n\n";

# parcourt des fichiers .prf
for( my $i = 0; $i <= $#ARGV; $i++ ){
  my $fileName = $ARGV[$i];
  open( DATA_FILE, $fileName ) or warn("\n" . $fileName . ": " . $!);
  print STDERR  "Lit: $fileName" if defined $echo;
  # on lit dans les fichiers
  $entete = 1;
  while( <DATA_FILE> ){ 
    if( $entete ) {	  
      # decode l'entete   	  
      # les numeros de profils ne sont pas present dans les entetes
      # on utilise le numero du fichier correspondant
      if( $fileName =~ /.+$cruisePrefix(\d{$stationPrefixLength})/i ) {
        $profil = $1;
      }  
      # atention, le format des dates est qq peu exotique dans la version 8
      # il faut traiter les blancs eventuels:    
      # Date = 2007/ 1/14
      # format standard dans la version 10.8
      # Date        = 2012/03/22
      # Start_Time  = 15:09:24
      if( m[Date\s*=\s*(\d+)/\s*(\d+)/\s*(\d+)]i ) {
	my ($mois, $jour, $annee) = ($2, $3, $1);
        $date = sprintf( "%02d/%02d/%04d", $mois, $jour, $annee );
	chomp;
      }	
      # idem pour l'heure:       Start_Time = 0:24: 6
      if( /Start_Time\s*=\s*(\d+):\s*(\d+):\s*(\d+)/i ) {
        my ($heure, $minute, $seconde) = ($1, $2, $3);
        $time = sprintf( "%02d:%02d:%02d", $heure, $minute, $seconde );
	chomp;
      }
      # Latitude    = 10.5047
      if( /Latitude\s*=\s*(-?\d+\.\d+)/ ) {
        ($lat) = ($1);
        ($lat_deg, $lat_min, $lat_sec, $lat_hemi) = &HtoHMS($lat,'lat');
      }
      # Longitude   = -19.0057
      if( /Longitude\s*=\s*(-?\d+\.\d+)/ ) {
        ($long) = ($1);
        ($long_deg, $long_min, $long_sec, $long_hemi) = &HtoHMS($long,'long');
      }	

      # fin d'entete, les etoiles  
      if( ( /Columns/) ) {
        $date = $date . " " . $time;
        # debug
	#printf STDERR "Date: %s\n", $date;
	#printf STDERR "Lat: %f  Long: %f\n", $lat, $long;

        $date = &ParseDate($date );
        # transforme le day_of_year en julian day
        #$julien = &UnixDate($time,"%j") -1;
        $julien = &julian( &UnixDate($date,"%j") -1,
                           &UnixDate($date,"%H"),&UnixDate($date,"%M"),
	                   &UnixDate($date,"%S") );
        $h_date = &UnixDate($date,"%d/%m/%Y %H:%M");
   	      
        # ecrit l'entete en decimale 
        printf LADCP_FILE "%05d  %6.1f %9.5f %8.5f %9.5f %s\n",
          $profil,$code,$julien,$lat,$long,&UnixDate($date,"%q");
        # affiche l'entete profil a l'ecran	 
	printf STDERR "   %05d %s %02d°%02d.%02d %s %03d°%02d.%02d %s",$profil,
          $h_date, $lat_deg, $lat_min, $lat_sec, $lat_hemi, $long_deg, $long_min,
          $long_sec, $long_hemi if defined $echo;
        # ecrit dans le fichiers des entetes
        printf HDR_FILE  "%05d %s %02d°%02d.%02d %s %03d°%02d.%02d %s",$profil,
          $h_date, $lat_deg, $lat_min,  $lat_sec, $lat_hemi, $long_deg, $long_min,
          $long_sec, $long_hemi;
  	$entete = 0;
  	next;
      } 
    }  
    else {
      ($depth,$U,$V,$ev) = split;
      $U *= 100;
      $V *= 100;  
      # ecriture dans la fichier 
      printf LADCP_FILE "%05d  %6.1f  %+5.1f  %+5.1f    1e36    1e36\n", 
        $profil,$depth,$U,$V;
    }	
  }  
  # termine l'affichage de l'entete profil a l'ecran	 
  printf STDERR " %5.4g\n", $depth if defined $echo;
  printf HDR_FILE " %4.4g\n", $depth;
  # on re-initialise l'ensemble des variables, afin de ne pas memoriser
  # les valeurs d'un profil au suivant en cas de mauvais decodage
  $depth=$profil=$h_date=$lat_deg=$lat_min=$lat_hemi=$long_deg=$long_min=undef; 
  $long_hemi=$julien=$lat=$long=$U=$V=$ev=undef;	  
  $. = 0; # remet le compteur de ligne a zero

  close DATA_FILE;
}

# return result for matlab
# print STDERR $ladcp_file;

if( defined $xml ) {
  print  LADCP_FILE "  </DATA>\n";  
  print  LADCP_FILE "</OCEANO>\n";  
}  
close LADCP_FILE;


