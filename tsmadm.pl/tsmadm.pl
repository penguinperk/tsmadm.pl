#!/usr/bin/perl

#
#    _                           _                       _
#   | |_ ___ _ __ ___   __ _  __| |_ __ ___        _ __ | |
#   | __/ __| '_ ` _ \ / _` |/ _` | '_ ` _ \      | '_ \| |
#   | |_\__ \ | | | | | (_| | (_| | | | | | |  _  | |_) | |
#    \__|___/_| |_| |_|\__,_|\__,_|_| |_| |_| (_) | .__/|_|
#                                                 |_|
#              Visit at: http://www.tsmadm.pl/
#              FYI: I stopped paying for the domain so there is no webpage from 201306. Sorry for this! :-(

# tsmadm.pl is an open source multi platform really task oriented IBM Tivoli Storage Manager command line interface
#
# Designed by _flex and Marcell
# Written by _flex from FleXoft and Marcell.
#   (flex@tsmadm.pl) (marcell@tsmadm.pl)
# Use this one from 201306: tsmadmpl@fleischmann.hu
#
# v3.00.$Rev$, 2013.06.18. Budapest, FleXoft
#	Add:	improved version
#       Txt:    start v3
#
# v2.00, 2012.01.01. Budapest, FleXoft
#	Add:	improved version
#	Bfx:	several bfxs
#
# v1.00, 2011.06.01. Budapest, FleXoft
#	Rls:	first release
#
# Requirements:
# -------------
#
#      Perl:
#
#      tested on:
#        ActivePerl 5.16.3 Build 1603 MS Windwos + Command Line Administrative Interface - Version 6, Release 2, Level 4.7
#
#  not working on:
#
#    HP-UX: missing GetOptionsFromArray
#       This is perl, v5.8.8 built for IA64.ARCHREV_0-thread-multi on HP-UX
#
# Documentation:
# --------------
#
#      Tested on:
#        HPUX (B.11.11)
#        HP-UX tsm1 B.11.31 U ia64 2778331787 unlimited-user license

#        MS Windows (Version 5.1 (Build 2600.xpsp_sp2_gdr.050301-1519 : Service Pack 2))
#        systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
#        Microsoft Windows XP Professional 5.1.2600 Service Pack 3 Build 2600
#        Sun Solaris 9 ()
#        Debian Linux ()
#
#      with TSM servers:
#        Server Version 5, Release 5, Level 5.2
#        Server Version 6, Release 2, Level x
#        Server Version 6, Release 3, Level x
#
# TODO:
# -----
#
# =========================================================================
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to
# the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
#
# *************************************************************************

use strict;
use warnings;

require 5.008_000;    # perl 5.10.0... compatible

# store the starting time
my $starttime = time;

# and get the starting dir
our $Dirname = dirname($0);    #
our @History;
our $HistoryPointer = 0;

# load perl modules
use Time::Local;
#use Getopt::Long;
use Getopt::Long qw(GetOptionsFromArray);
use File::Path;
use File::Spec;
use File::Spec::Functions;
use File::Basename;
use Pod::Usage;
use utf8;

use Net::SMTP;

# load perl subroutines
require "$Dirname/subs/tsmadm_subroutines.pl";
require "$Dirname/subs/dsmadmc_subroutines.pl";
require "$Dirname/subs/printer_subroutines.pl";
require "$Dirname/subs/pbar_subroutines.pl";
require "$Dirname/subs/archive_subroutines.pl";
require "$Dirname/subs/wizard_subroutines.pl";
require "$Dirname/subs/christmas_present.pl";

# prepare options for Getopt
my $helpFlag;
my $manualFlag;
my $verboseFlag;
my $quietFlag;
my $configfileOption;
my $commandOption;
my $serverOption;
my $languageOption;
my $defaultColorOption;
my $nocolorFlag;
my $promptOptions;
my $Server;
my $disableGrep;
my $debugFlag;
my $consoleFlag;
my $wizardFlag;
my $colortestFlag;

if (
     !GetOptions(
                  "help"           => \$helpFlag,
                  "manual"         => \$manualFlag,
                  "debug"          => \$debugFlag,
                  "quiet"          => \$quietFlag,
                  "nocolor"        => \$nocolorFlag,
                  "console"        => \$consoleFlag,
                  "wizard"         => \$wizardFlag,
                  "server=s"       => \$serverOption,
                  "configfile=s"   => \$configfileOption,
                  "command=s"      => \$commandOption,
                  "language=s"     => \$languageOption,
                  "defaultcolor=s" => \$defaultColorOption,
                  "prompt=s"       => \$promptOptions,
                  "colortest"      => \$colortestFlag,
                )
   )
{
    exit 1;    # Wrong parameter usage!
}

# Help & Manual handling
pod2usage( -verbose => 1, -message => "tsmadm.pl" ) if ( defined($helpFlag) );
pod2usage( -verbose => 2, -message => "tsmadm.pl" ) if ( defined($manualFlag) );

# Global variables (Each starts with capital!)
our $tsmadmplVersion;              # version info
our %Settings;                     # Global settings hash
our %Messages;                     # Global message hash
our $LastErrorcode;                # Last dsmadmc error code
our $LastErrorMessage;             # Last dsmadmc error message
our $ExcludeList;                  #
our $TmpExcludeList;               # you can add more with 'exclude' command
our $OS_win;                       # Is it MS Windows?
our %ParameterRegExps;             #
our %ParameterRegExpValues;        # This hash stores the values
our %Commands;                     #
our %Aliases;                      #
our $LastCommandType;              #
our @LastResult;                   #
our %TSMSeverStatus;               #
our $CurrentPrompt;                #
our $CommandMode;                  # INTERACTIVE, BATCH
our %GlobalHighlighter;            #

# init globals
$ExcludeList = '^\s*$';    # dsmadmc exclude list
$ExcludeList .= '|^IBM Tivoli Storage Manager.*$';                           #
$ExcludeList .= '|^Tivoli Storage Manager.*$';                               #
$ExcludeList .= '|^Command Line Administrative Interface.*$';                #
$ExcludeList .= '|^\(c\) Copyright by IBM Corporation and other\(s\).*$';    #
$ExcludeList .= '|^\(C\) Copyright IBM Corporation.*$';                      #
$ExcludeList .= '|^Session established with server.*$';                      #
$ExcludeList .= '|^\s\sServer.*$';                                           #

#
$ExcludeList .= '|^ANS0102W.*$';                                             # ANS0102W QUERY PROCESS: No active processes found.

#
$ExcludeList .= '|^ANR0944E.*$';                                             # ANR0944E QUERY PROCESS: No active processes found.

#
$ExcludeList .= '|^ANR1462I.*$';                                             # ANR1462I RUN: Command script SCRIPTNAME completed successfully.

#
$ExcludeList .= '|^ANR1687I.*$';    # ANR1687I Output for command 'COMMAND' issued against server SERVERNAME follows:
$ExcludeList .= '|^ANR1688I.*$';    # ANR1688I Output for command 'COMMAND' issued against server SERVERNAME completed.
$ExcludeList .= '|^ANR1694I.*$';    # ANR1694I Server SERVERNAME processed command 'COMMAND' and complete d successfully.
$ExcludeList .= '|^ANR1695W.*$';    # ANR1695W Server SERVERNAME processed command 'COMMAND' but complet ed with warnings.
$ExcludeList .= '|^ANR1697I.*$';    # ANR1697I Command 'COMMAND' processed by ## server(s):  ## successful, # with warnings, and # with errors.
$ExcludeList .= '|^ANR1699I.*$';    # ANR1699I Resolved SITE to ## server(s) - issuing command COMMAND against server(s).

#
$ExcludeList .= '|^ANR2034E.*$';    # ANR2034E QUERY EVENT: No match found using this criteria.
$ExcludeList .= '|^ANR2624E.*$';    # ANR2624E QUERY EVENT: No matching nodes registered.

#
$ExcludeList .= '|^ANS8000I.*$';    #
$ExcludeList .= '|^ANS8001I.*$';    # ANS8001I Return code ##.
$ExcludeList .= '|^ANR8334I.*$';    # ANR8334I  # matches found.
$ExcludeList .= '|^ANR2662I.*$';    # ANR2662I (*) "Query schedule format=standard" displays an asterisk in the day of week column for enhanced schedules.

$TmpExcludeList = "";                                       # you can add more with 'exclude' command

$OS_win = ( $^O eq "MSWin32" ) ? 1 : 0;                     # Is it MS Windows?

%ParameterRegExps = (                                       # This hash helps to get the command parameters
    HIGHLIGHT => '\s+-+(highlight)=(.+)',                   #
    NOHISTORY => '\s+-+(nohistory)',                        #
    REPEAT    => '\s+-+(repeat)=(\d+x\d+|\d+)',             #
    NOCOLOR   => '\s+-+(nocolor)',                          #
    HTML      => '\s+-+(html)',                             #
    MAIL      => '\s+-+(mail)=(\w+@[\w+\.\w+]+)',           #
    HELP      => '\s+-+(help)',                             #
    HISTORY   => '\s+-+(archive|archiv|archi|arch|arc)',    #
    VERBOSE   => '\s+-+(verbose|verbos|verbo|verb)',        #
    LISTMODE  => '\s+-+(list)',                             #
    TABMODE   => '\s+-+(tab)',                              #

    SERVERCOMMANDROUTING1 => '(^\s*)([\w_\-\.]+):\s*',      # if you change thsese two regexps don't forget to change in the tsmadm_subroutine.pl
    SERVERCOMMANDROUTING2 => '(^\s*)\(([\w_\-\.]+)\)\s*',   # command routing reservation section

    INVGREP   => '\|\s*(invgrep)\s+["\']*([^$|"\']*)["\']*',          #
    PGREP     => '\|\s*(pgrep)\s+["\']*([^$|"\']*)["\']*',            #
    GREP      => '\|\s*(grep)\s+["\']*([^$|"\']*)["\']*',             #
    MORE      => '\|\s*(more)',                             #

    OUTPUT    => '(\>)\s*(.+)',                             # 
);

$CommandMode = "BATCH";                                     # INTERACTIVE, BATCH

# Global highlighter regexps (!CASE SENSITIVE!)
%GlobalHighlighter = (

    # errors and warnings
#    '([[:print:]\e]*ANR\d\d\d\dE[[:print:]\e]*)'                       => 'BOLD BLUE',
#    '([[:print:]\e]*ANR\d\d\d\dW[[:print:]\e]*)'                       => 'BOLD YELLOW',
    '^(AN[ER]\d\d\d\dE[A-Za-z _\.\-0-9:\\\/{}\e\[\];,:\(\)\']+)'        => 'BOLD RED',
    '^(ANR\d\d\d\dW[A-Za-z _\.\-0-9:\\\/{}\e\[\];,:\(\)\']+)'           => 'BOLD YELLOW',
#    '(AN[ER]\d\d\d\dE)'                       => 'BOLD RED',
#    '(ANR\d\d\d\dW)'                          => 'BOLD YELLOW',

    # volumes
    #'[^A-Z0-9]([A-Z]{1}[0-9]{5})[^A-Z0-9_]'                            => 'BOLD GREEN',
    #'[^A-Z0-9]([A-Z]{3}[0-9]{3})[^A-Z0-9_]'                            => 'BOLD GREEN',
    #'[^A-Z0-9]([A-Z,0-9]{6}J[ABXW])[^A-Z0-9_]'                         => 'BOLD GREEN',
    #'[^A-Z0-9]([A-Z,0-9]{6}L[12345])[^A-Z0-9_]'                        => 'BOLD GREEN',
    
    #'[^A-Za-z0-9\.\\\/]([A-Za-z_\.\-0-9:\\\/\e\[\;]+\.BFS\.?[0-9]{0,9})' => 'BOLD GREEN',
    #'[^A-Za-z0-9\.\\\/]([A-Za-z_\.\-0-9:\\\/\e\[\;]+\.DBB\.?[0-9]{0,9})' => 'BOLD GREEN',
    #'[^A-Za-z0-9\.\\\/]([A-Za-z_\.\-0-9:\\\/\e\[\;]+\.DBV\.?[0-9]{0,9})' => 'BOLD GREEN',

    # sessions
    '(MediaW)'                                                         => 'BOLD RED',

    '(Waiting for multiple mount points in device class \w*)'          => 'BOLD YELLOW',
    '(Waiting for mount point in device class \w*)'                    => 'BOLD YELLOW',
    '(Waiting for mount of output volume \w*)'                         => 'BOLD YELLOW',
    '(Waiting for mount of input volume \w*)'                         => 'BOLD YELLOW',
    
    # mounts
    '(RESERVED)'                                                       => 'BOLD YELLOW',
    '(DISMOUNTING)'                                                    => 'BOLD YELLOW',
    '(WAITING FOR VOLUME)'                                             => 'BOLD RED',

    # PATHs
    '(ONL=NO)'                                                         => 'BOLD RED',

    # message based highlighting v3
    'Last Full Volume\t(\w{6,8})\t'                                    => 'BOLD GREEN',

    #'\d+\t\w+\t\w+\tONL=\w+\t\d+\t\w+\t\d+\t(\w{6,8})'                 => 'BOLD GREEN',
    #'\d+\t\w+\t\w+\tONL=\w+\t\d+\t\w+\t\d+\t(\w{6,8})\t'               => 'BOLD GREEN',
    #'\d\d\d\d\-\d\d\-\d\d\t\d\d\:\d\d\:\d\d\t(\w)' => 'BOLD GREEN',
    
    'Current output volume: ([A-Za-z_\.\-0-9:\\\/{}]+)\.'              => 'BOLD GREEN',
    'Current output volume{{s}}: ([A-Za-z_\.\-0-9:\\\/{}]+)\.'         => 'BOLD GREEN',
    'Current input volume: ([A-Za-z_\.\-0-9:\\\/{}]+)\.'               => 'BOLD GREEN',
    'Waiting for access to input volume ([A-Za-z_\.\-0-9:\\\/{}]+) {{\d+ seconds}}\.' => 'BOLD GREEN',
        
    'ANR8468I \w+ volume ([A-Za-z_\.\-0-9:\\\/{}]+) dismounted from drive' => 'BOLD GREEN',
    'ANR8336I Verifying label of \w+ volume ([A-Za-z_\.\-0-9:\\\/{}]+) in drive'=> 'BOLD GREEN',
    'ANR8337I \w+ volume ([A-Za-z_\.\-0-9:\\\/{}]+) mounted in drive'  => 'BOLD GREEN',

    'ANR0510I Session \d+ opened input volume ([A-Za-z_\.\-0-9:\\\/{}]+)\.' => 'BOLD GREEN',
    'ANR0511I Session \d+ opened output volume ([A-Za-z_\.\-0-9:\\\/{}]+)\.' => 'BOLD GREEN',
    'ANR0512I Process \d+ opened input volume ([A-Za-z_\.\-0-9:\\\/{}]+)\.'  => 'BOLD GREEN',
    'ANR0513I Process \d+ opened output volume ([A-Za-z_\.\-0-9:\\\/{}]+)\.' => 'BOLD GREEN',
    
    'ANR0514I Session \d+ closed volume ([A-Za-z_\.\-0-9:\\\/{}]+)\.'  => 'BOLD GREEN',
    'ANR0515I Process \d+ closed volume ([A-Za-z_\.\-0-9:\\\/{}]+)\.'  => 'BOLD GREEN',
    
    'ANR1157I Removable volume ([A-Za-z_\.\-0-9:\\\/{}]+) is required for move process\.' => 'BOLD GREEN',
    'ANR1228I Removable volume ([A-Za-z_\.\-0-9:\\\/{}]+) is required for storage pool backup\.' => 'BOLD GREEN',

    'ANR1140I Move data process started for volume ([A-Za-z_\.\-0-9:\\\/{}]+) ' => 'BOLD GREEN',
    'ANR1141I Move data process ended for volume ([A-Za-z_\.\-0-9:\\\/{}]+)\.' => 'BOLD GREEN',

    'ANR8337I \w+ volume ([A-Za-z_\.\-0-9:\\\/{}]+) mounted in drive ' => 'BOLD GREEN',
    
    'ANR8329I .+ volume ([A-Za-z_\.\-0-9:\\\/{}]+) is mounted'         => 'BOLD GREEN',
    'ANR8330I .+ volume ([A-Za-z_\.\-0-9:\\\/{}]+) is mounted'         => 'BOLD GREEN',
    'ANR8331I .+ volume ([A-Za-z_\.\-0-9:\\\/{}]+) is mounted'         => 'BOLD GREEN',
    
    'ANR1360I Output volume ([A-Za-z_\.\-0-9:\\\/{}]+) opened '        => 'BOLD GREEN',
    'ANR1361I Output volume ([A-Za-z_\.\-0-9:\\\/{}]+) closed\.'      => 'BOLD GREEN',
    
    'ANR8340I \w+ volume ([A-Za-z_\.\-0-9:\\\/{}]+) mounted\.'         => 'BOLD GREEN',
    'ANR8341I End-of-volume reached for \w+ volume ([A-Za-z_\.\-0-9:\\\/{}]+)\.' => 'BOLD GREEN',
    
    'ANR1340I Scratch volume ([A-Za-z_\.\-0-9:\\\/{}]+) is now defined in storage pool ' => 'BOLD GREEN',
    'ANR1341I Scratch volume ([A-Za-z_\.\-0-9:\\\/{}]+) has been deleted from storage pool ' => 'BOLD GREEN',
    
    #???
    #'Volume ([A-Za-z_\.\-0-9:\\\/{}]+)'                                => 'BOLD GREEN',
    
    'Examined (\d+) objects, deleting'                                 => 'BOLD GREEN',
    'objects, deleting (\d+) backup objects,'                          => 'BOLD GREEN',
    'backup objects, (\d+) archive objects,'                           => 'BOLD GREEN',
    'Full backup: (\d+) pages of '                                     => 'BOLD GREEN',
    'pages of (\d+) backed up\.'                                       => 'BOLD GREEN',
    'Unreadable Bytes: ([\d,]*\d*[123456789])\.'                       => 'BOLD RED',

);

##########################################################################################
# main()
##########################################################################################

# get the version info first
open my $MYSELF, "<$0" or die;
while (<$MYSELF>) {
    if (/^# v(\d+\.\d{2}),/) {
        $tsmadmplVersion = $1;
        last;
    }
}
close $MYSELF or die;

$Settings{HOMEDIRECTORY} = "";

# OS
if ( $OS_win ) {

    # MS Windows environments
    require Win32;
    require Win32::Console;
    require Win32::Console::ANSI;

    $Settings{HOMEDIRECTORY} = File::Spec->canonpath( $ENV{HOMEDRIVE}.$ENV{HOMEPATH} );

}
else {

    # UNIX like environments
    use Term::ReadKey;
    use Term::ANSIColor;
    $Settings{HOMEDIRECTORY} = $ENV{HOME};

}

# load config file DON'T MOVE THIS SECTION!
if ( !defined($configfileOption) ) {
    # default config file
    $configfileOption = File::Spec->canonpath( "$Settings{HOMEDIRECTORY}/.tsmadm/tsmadm.conf" );
}

$Settings{CONFIGFILE} = $configfileOption;

# Wizard
if ( defined($wizardFlag) ) {
    &wizard;
    exit 666;
}

# check Configfile 
if (! -r $Settings{CONFIGFILE} ) {
    print "Config file ($Settings{CONFIGFILE}) can not be found, or not readable! Starting Configuration Wizard...\n";
    &wizard;
    exit 666;
}

&checkPassword($configfileOption);

%Settings = &loadFileToHash($configfileOption);

if ($OS_win) {
    $Settings{HOMEDIRECTORY} = $ENV{HOMEDRIVE} . $ENV{HOMEPATH};
} else {
    $Settings{HOMEDIRECTORY} = $ENV{HOME};
}

$Settings{CONFIGFILE} = $configfileOption;

# put it to the right place and use from here
 
$Settings{HISTORYFILE}      = File::Spec->canonpath( "$Settings{HOMEDIRECTORY}/.tsmadm/command_history" );
$Settings{ARCHIVEDIRECTORY} = File::Spec->canonpath( "$Dirname/archives" );
$Settings{CLOPTSETS}        = File::Spec->canonpath( "$Dirname/cloptsets" );
$Settings{SCRIPTS}          = File::Spec->canonpath( "$Dirname/scripts" );

# load language file
if ( defined($languageOption) ) {
    $Settings{LANGUAGE} = $languageOption;
}
elsif ( !defined( $Settings{LANGUAGE} ) ) {
    $Settings{LANGUAGE} = "en_US";
}

%Messages = &loadFileToHash( File::Spec->canonpath( "$Dirname/languages/" . $Settings{LANGUAGE} . ".txt" ) );

&updateTerminalSettings();

&checkDefaults();

if ( defined($defaultColorOption) && defined($nocolorFlag) ) {
    pod2usage(
               {
                -verbose => 1,
                -exitval => 1,
                -message => "--defaultcolor and --nocolor are mutually exclusive.\n"
               }
             );
}

# default color
if (
     defined($defaultColorOption)
     && (    uc($defaultColorOption) eq "RED"
          || uc($defaultColorOption) eq "BLUE"
          || uc($defaultColorOption) eq "WHITE"
          || uc($defaultColorOption) eq "BLACK"
          || uc($defaultColorOption) eq "YELLOW"
          || uc($defaultColorOption) eq "MAGENTA"
          || uc($defaultColorOption) eq "CYAN"
          || uc($defaultColorOption) eq "GREEN" )
   ) {

    $Settings{DEFAULTCOLOR} = uc($defaultColorOption);
}
elsif ( !defined( $Settings{DEFAULTCOLOR} ) ) {

    # $Settings{DEFAULTCOLOR} = "WHITE";
}

# nocolor
if ( defined($nocolorFlag) ) {
    $Settings{NOCOLOR} = 1;
}
elsif ( !defined( $Settings{NOCOLOR} ) ) {
    $Settings{NOCOLOR} = 0;
}

# prompt
if ( defined($promptOptions) ) {
    $Settings{PROMPT} = $promptOptions;
}
elsif ( !defined( $Settings{PROMPT} ) ) {
    $Settings{PROMPT} = "TSMADM: ";
}

# Server
if ( defined($serverOption) ) {
    $Settings{SERVER} = uc("$serverOption");
}
elsif ( !defined( $Settings{SERVER} ) ) {
    $Settings{SERVER} = $Settings{DEFAULTSERVER};
}

# Disable Grep
if ( defined($disableGrep) ) {
    $Settings{DISABLEGREP} = 1;
}
elsif ( !defined( $Settings{DISABLEGREP} ) ) {
    $Settings{DISABLEGREP} = 0;
}

if ( ! defined( $Settings{GREPCOLOR} )  ) {
    $Settings{GREPCOLOR} = 'BOLD WHITE';   
}

$Settings{OS} = $^O;

if ( defined($quietFlag) && defined($debugFlag) ) {
    pod2usage(
               {
                -verbose => 1,
                -exitval => 1,
                -message => "--quiet and --debug are mutually exclusive.\n"
               }
             );
}

#quiet flag
if ( defined($quietFlag) ) {
    $Settings{QUIET} = 1;
    $Settings{DEBUG} = 0;
}
else {
    $Settings{QUIET} = 0;
}

if ( defined($debugFlag) ) {
    $Settings{DEBUG} = 1;
}
else {
    $Settings{DEBUG} = 0;
}

if ( defined($consoleFlag) ) {
    print &colorString( "Starting Console Highlighter...\n", "BOLD RED" );
    &consoleHighlighter;
    exit 0;
}

$LastCommandType = 'NOCOMMANDS';

#print &christmasTree();

# Welcome message
print colorString( "", $Settings{DEFAULTCOLOR} );
&msg( '0000C', &colorString( "tsmadm.pl ", 'WHITE' ).&colorString( 'v'.$tsmadmplVersion, 'BOLD WHITE' ) );

# colortest only
if ( defined($colortestFlag) ) {
    print &textLine( &colorString( "#", $Settings{DEFAULTCOLOR} ).&colorString( " Colortest begin ", "BOLD RED" ), '#');
    print &textLine( &colorString( "#", $Settings{DEFAULTCOLOR} ).&colorString( " Highlighter [ ABC123JA X ", "BOLD YELLOW" ).&colorString( '], [', "BLUE" ). &colorString( " ABC456L5 ] ", "BOLD WHITE" ), '#');
    print &globalHighlighter( &textLine( &colorString( "#", $Settings{DEFAULTCOLOR} ).&colorString( " Highlighter [ ABC123JA X ", "BOLD YELLOW" ).&colorString( '], [', "BLUE" ). &colorString( " ABC456L5 ] ", "BOLD WHITE" ), '#') );
    
    print &globalHighlighter( "Primary Pool MKB_OS4_J, Copy Pool MKB_OS4_C1_J, Files Backed Up: 24, Bytes Backed Up: 1,134,000,815,259, Unreadable Files: 0, Unreadable Bytes: 0. Current Physical File (bytes): 246,120,144,486 Current input volume: A00448JA. Current output volume: MKB510JA.\n" );
    print &globalHighlighter( "Volume MKB195JA (storage pool MKB_SQL_C1_J), Moved Files: 4, Moved Bytes: 7,904,512, Unreadable Files: 0, Unreadable Bytes: 0. Current Physical File (bytes): 55,534,602,514 Current input volume: MKB195JA. Current output volume: MKB216JA.\n" );

    print &globalHighlighter( "Incremental backup: 0 pages of 77452 backed up. Current output volume: /tsm/blackhole/dbDailyIncrements/21536884.DBB.\n" );
    print &globalHighlighter( 'Incremental backup: 0 pages of 77452 backed up. Current output volume: D:\tsm\blackhole\dbDailyIncrements\21536884.DBB.'."\n" );

    print &globalHighlighter( "Incremental backup: 0 pages of 77452 backed up. Current output volume: /tsm/blackhole/dbDailyIncrements/21536884.DBB.1212122.\n" );
    print &globalHighlighter( 'Incremental backup: 0 pages of 77452 backed up. Current output volume: D:\tsm\blackhole\dbDailyIncrements\21536884.DBB.12121.'."\n" );

    print &globalHighlighter( "ANR2020E Incremental backup: 0 pages of 77452 backed up. Current output volume: /tsm/blackhole/dbDailyIncrements/21536884.DBB.\n" );
    print &globalHighlighter( 'ANR2020E Incremental backup: 0 pages of 77452 backed up. Current output volume: D:\tsm\blackhole\dbDailyIncrements\21536884.DBB.'."\n" );

    print &globalHighlighter( "ANR2020W Incremental backup: 0 pages of 77452 backed up. Current output volume: /tsm/blackhole/dbDailyIncrements/21536884.DBB.1212122.\n" );
    print &globalHighlighter( 'ANR2020W Incremental backup: 0 pages of 77452 backed up. Current output volume: D:\tsm\blackhole\dbDailyIncrements\21536884.DBB.12121.'."\n" );

    print &globalHighlighter( "ANR2020E RECLAIM STGPOOL: Invalid parameter - TRE.\n" );
    print &globalHighlighter( "TSMADM [USERTSM.SR]:reclaim stgp files_vtl tres60\n" );

    print &globalHighlighter( "ANR2020W RECLAIM STGPOOL: Invalid parameter - TRE.\n" );
    print &globalHighlighter( "TSMADM [USERTSM.SR]:reclaim stgp files_vtl tres60\n" );
    
    print &globalHighlighter( 'ANR2020E RECLAIM STGPOOL: Invalid para\\\\meter - TRE.'."\n" );
    print &globalHighlighter( 'ANR2020W RECLAIM STGPOOL: Invalid para /tsm/alam.DBB meter - TRE.'."\n" );
    
    print 'ANR8209E Unable to establish TCP/IP session with 10.16.2.234 - connection refused. (SESSION: 94)'."\n" ;
    print &globalHighlighter( 'ANR8209E Unable to establish TCP/IP session with 10.16.2.234 - connection refused. (SESSION: 94)'."\n" );
    
    print &textLine( &colorString( "#", $Settings{DEFAULTCOLOR} ).&colorString( " Colortest GREP section ", "BOLD RED" ), '#');
    
    $ParameterRegExpValues{GREP} = "dbDailyIncrements";
    print &grepIt( &globalHighlighter( "ANR2020E Incremental backup: 0 pages of 77452 backed up. Current output volume: /tsm/blackhole/dbDailyIncrements/21536884.DBB.\n" ));
    print &grepIt( &globalHighlighter( 'ANR2020E Incremental backup: 0 pages of 77452 backed up. Current output volume: D:\tsm\blackhole\dbDailyIncrements\21536884.DBB.'."\n" ));
    
    $ParameterRegExpValues{GREP} = "full";    
    print &grepIt( &globalHighlighter( "01/09/2012 06:04:29      BACKUPFULL            842             0          1     DCFILE_01        /tsmdata/full/26085469.DBB\n" ));
    print &grepIt( &globalHighlighter( "01/09/2012 06:04:29      BACKUPFULL            842             0          1     DCFILE_01        /tsmdata/full/26085469.DBB\n" ));
        
    print &globalHighlighter("Primary Pool DB2_VTL, Copy Pool DB2_C_LTO, Files Backed Up: 295, Bytes Backed Up: 666,553,401,841, Unreadable Files: 0, Unreadable Bytes: 0. Current Physical File (bytes): 228,001,965,291 Current input volume: V00359. Current output volume(s): B00252L3."."\n" );
    print &globalHighlighter("Current input volume: V00359. Current output volume(s): B00252L3."."\n" );
        
    print &textLine( &colorString( "#", $Settings{DEFAULTCOLOR} ).&colorString( " Colortest end ", "BOLD RED" ), '#');
    exit 99;
}

Getopt::Long::Configure("pass_through");

# load plugins
&reLoadPlugins();

# set server
&setServer( $Settings{SERVER} )
  if ( defined( $Settings{SERVER} ) && $Settings{SERVER} ne "" );

# update prompt
&updatePrompt();

# signal
#$SIG{INT} = \&sigInt;

# if command parameter was used then do it
if ( defined( $commandOption ) && &commandSplitterParserExecuter($commandOption) == 1 ) {
    ;
}
# if AUTOEXEC parameter was used in the config file then do it
elsif ( defined( $Settings{AUTOEXEC} ) && &commandSplitterParserExecuter( $Settings{AUTOEXEC} ) == 1 ) {
    ;
}
else {

    $CommandMode = "INTERACTIVE";

    # main loop
    INFINITELOOP: while ( 1 ) {

        print $CurrentPrompt;
        my $command = &readCommand;

        next if ( ! defined($command) );

        chomp( $command );
        $command =~ s/^\s+//;

        last if ( &commandSplitterParserExecuter( $command ) == 1 );

    }    # END of infinite loop
}

# End summary
&msg( '9900I', &colorString( &msgSpentTime( time - $starttime ), 'BOLD WHITE' ) );
&msg( '9901I', &colorString( 'http://tsmadm.pl/', 'BOLD GREEN' ) );
&msg( '9999I' );
sleep (1);

__END__

=head1 NAME

tsmadm.pl - Advanced Tivoli Storage Manager Administration Client

=head1 SYNOPSIS

B<tsmadm.pl --help>

B<tsmadm.pl --manual>

B<tsmadm.pl --wizard>

B<tsmadm.pl --console> [ B<--server> I<serverName> ]

B<tsmadm.pl> [ B<--debug> | B<--quiet> ] [ B<--nocolor> | B<--defaultcolor> I<defaultColor> ] [ B<--server> I<serverName> ] [ B<--configfile> I<configFile> ]
[ B<--command> I<command> ] [ B<--language> I<language> ] [ B<--prompt> I<prompt> ]

=head1 DESCRIPTION

B<tsmadm.pl> is a command line wrapper for dsmadmc, the administration client to IBM's Tivoli Storage Management server. It helps you with an extensive and extensible command set, highlighting, better output formatting, and high customizability.

=head1 OPTIONS

=over 4

=item B<--help>

Help about the command line arguments and options. After this tsmadm.pl will exits

=item B<--manual>

A complete manual page about the tsmadm. After this the program will exits

=item B<--debug>

Debug mode

=item B<--wizard>

Starts configuration wizard

=item B<--console>

Console mode, like in dsmadmc + color highlighting

=item B<--quiet>

The silent mode switch.

=item B<--nocolor>

Use this option if your terminal doesnot understand the coloring escape sequences. (eg. you see something like this: \e[xx.xx)

=item B<--server> I<server>

Connect to the specifed server, after start. (A szervernek szerepelnie kell a config f‡jlban)

=item B<--configfile> I<configFile>

Use alternate configfile (the default is <HOMEDIRECTORY>/.tsmadm/tsmadm.conf)

=item B<--command> I<commands>

Like autoexec.bat :-) try this: --command 'q sess; q pr; quit'

=item B<--defaultcolor> I<defaultColor>

Possible colors are: WHITE, BLACK, RED, BLUE, MAGENTA, YELLOW, GREEN, CYAN

=item B<--language> I<language>

You can use your own language file from I<languages/> directory.

=item B<--prompt> I<value>

The value of this parameter is used as the prompt string.

=back

=head1 FILES

=over 4

=item B<~/.tsmadm/>

This folder contains your personal I<tsmadm.pl> command-line history

=item B<tsmadm.pl>

The perl program

=back

=head1 DIAGNOSTICS

Please see I<languages/*.txt> file for more and possible error messages. The languages directory can be found in your installation directory, by default: /opt/tsmadm/

=head1 REQUIRES

Perl 5.008, Term::ReadKey, Getopt::Long, Pod::Usage, List::Util, Term::ANSIColor, Win32::Console::ANSI (only on windows), File::Path, File:Basename

=head1 SEE ALSO

TSMADM Installation Guide, TSMADM Administration and User's Guide, TSMADM Plug-in Developer's Guide, L<Tivoli Storage Manager|http://www-01.ibm.com/software/tivoli/products/storage-mgr/>, L<IBM|http://www.ibm.com>

=head1 COPYRIGHT

L<GNU General Public License, Version 2|http://www.gnu.org/licenses/old-licenses/gpl-2.0.html>

=head1 AUTHORS

The Fantastic Three

=cut
