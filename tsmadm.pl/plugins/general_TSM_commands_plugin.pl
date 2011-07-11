#!/usr/bin/perl

use strict;
use warnings;

# Global variables (Each starts with capital!)
our $Dirname;                      #
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
our @History;                      #

# show session
# show processis
# show scratches
# kill
# reach
# show disks
# show timing
# show drives

# show path
# on off

# show status
# show libvolumes
# show assoc
# delete assoc

#################
# Show SESsions ########################################################################################################
#################
&msg( '0110D', 'SHow SESsions' );
$Commands{&commandRegexp( "show", "sessions" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "show sessions Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @query = &runTabdelDsmadmc( "select SESSION_ID,STATE,WAIT_SECONDS,BYTES_SENT,BYTES_RECEIVED,SESSION_TYPE,CLIENT_PLATFORM,CLIENT_NAME,INPUT_VOL_ACCESS,OUTPUT_VOL_ACCESS from sessions","select_x_from_sessions" );
    #,OWNER_NAME,MOUNT_POINT_WAIT,INPUT_MOUNT_WAIT,INPUT_VOL_WAIT,INPUT_VOL_ACCESS,OUTPUT_MOUNT_WAIT,OUTPUT_VOL_WAIT,OUTPUT_VOL_ACCESS,LAST_VERB,VERB_STATE
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = "SESSION";

    my @printable;

    foreach ( @query ) {
        my @line = split ( /\t/ );
        $line[2] = &timeFormatter ( $line[2], 's' );
        $line[3] = &byteFormatter ( $line[3], 'B' );
        $line[4] = &byteFormatter ( $line[4], 'B' );

        $line[8] = "" if ( ! defined ( $line[8] ) );
        $line[9] = "" if ( ! defined ( $line[9] ) );

        push ( @printable, join( "\t", $line[0], $line[1], $line[2], $line[3], $line[4], $line[5], $line[6], $line[7], $line[8].$line[9] ) )
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tId\tState\tWait\tSent{RIGHT}\tReceived{RIGHT}\tType\tPlatform\tName\tMediaAccess", &addLineNumbers( @printable ) );
    #\tOWNER_NAME\tMOUNT_POINT_WAIT\tINPUT_MOUNT_WAIT\tINPUT_VOL_WAIT\tINPUT_VOL_ACCESS\tOUTPUT_MOUNT_WAIT\tOUTPUT_VOL_WAIT\tOUTPUT_VOL_ACCESS\tLAST_VERB\tVERB_STATE

    return 0;

};
&defineAlias( 'ls',   'show session' );
&defineAlias( 'ps',   'show session' );
&defineAlias( 'ses',  'show session' );
&defineAlias( 'sess', 'show session' );

#################
# SHow PROcesses ########################################################################################################
#################
&msg( '0110D', 'SHow PROcesses' );
$Commands{&commandRegexp( "show", "processes" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow PROcesses Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @query = &runTabdelDsmadmc( "select PROCESS_NUM,PROCESS,FILES_PROCESSED,BYTES_PROCESSED,STATUS from processes","select_x_from_processes" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = "PROCESS";

    my @printable;

    foreach ( @query ) {
        my @line = split ( /\t/ );

        $line[3] = &byteFormatter ( $line[3], 'B' );

        push ( @printable, join( "\t", @line ) )
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tProc#\tProcess\tFiles{RIGHT}\tBytes{RIGHT}\tStatus", &addLineNumbers( @printable ) );

    return 0;

};
&defineAlias( 'q proc', 'show processes' );
&defineAlias( 'qp roc', 'show processes' );
&defineAlias( 'proc',   'show processes' );

##################
# Show SCRatches #######################################################################################################
##################
&msg( '0110D', 'SHow SCRatches' );
$Commands{&commandRegexp( "show", "scratches" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow SCRatches Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @query = &runTabdelDsmadmc( "select LIBRARY_NAME, count(*) from libvolumes where upper(status)='SCRATCH' group by LIBRARY_NAME", "select_lib_scratches_from_libvolumes" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'GENERAL';

    if ( $ParameterRegExpValues{HISTORY} ) {

        my @archive = &initArchiveRetriever ( 'select_lib_scratches_from_libvolumes' );
        return 0 if ( $#archive < 0 );

        while ( 1 ) {

            &setSimpleTXTOutput();
            &universalTextPrinter( "LibraryName\t#Scratch", @archive );

            @archive = &archiveRetriever();
            last if ( $#archive < 0 );

        }

    }
    else {

        &setSimpleTXTOutput();
        &universalTextPrinter( "LibraryName\t#Scratch", @query );

    }

    return 0;

};
&defineAlias( 'scr', 'show scratches' );

##################
# Show MAXscratch #####################################################################################################
##################
&msg( '0110D', 'SHow MAXscratch' );
$Commands{&commandRegexp( "show", "maxscratch" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow MAXscratch Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @query = &runTabdelDsmadmc( "SELECT STGPOOLS.STGPOOL_NAME, STGPOOLS.MAXSCRATCH, Count(1) FROM STGPOOLS,VOLUMES WHERE (VOLUMES.STGPOOL_NAME = STGPOOLS.STGPOOL_NAME) GROUP BY STGPOOLS.STGPOOL_NAME, STGPOOLS.MAXSCRATCH" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'GENERAL';

    if ( $ParameterRegExpValues{HISTORY} ) {

        my @archive = &initArchiveRetriever ( 'select_stgp_scratches_from_stgpvolumes' );
        return 0 if ( $#archive < 0 );

        while ( 1 ) {

            &setSimpleTXTOutput();
            &universalTextPrinter( "StgPool\t#Scratch\t#Volumes", @archive );

            @archive = &archiveRetriever();
            last if ( $#archive < 0 );

        }

    }
    else {

        &setSimpleTXTOutput();
        &universalTextPrinter( "StgPool\t#Scratch\t#Volumes", @query );

    }

    return 0;

};
&defineAlias( 'scr', 'show scratches' );

########
# KIll #######################################################################################################
########
&msg( '0110D', 'KILl' );
$Commands{&commandRegexp( "kill", "" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "KILl Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my $number = $2;

    if ( $number eq '' ) {
        &msg ( '0030E' );  # missing
        return 0;
    }

    if ( defined( $LastCommandType ) && $LastCommandType =~ m/SESSION|PROCESS/ ) {

        if ( $number =~ m/\d+/ ) {

            $number--;

            if (  $number <= $#LastResult ) {

                my ( $num, $session ) = split ( /\t/, $LastResult[$number] );

                #&msg ( '0030I' );
                &universalTextPrinter( "NOHEADER", &runDsmadmc( "cancel $LastCommandType $session" ) );

            }
            else {

                &msg ( '0032E' ); # out of range

            }

        }
        elsif ( uc( $number ) eq 'ALL' ) {

            foreach ( @LastResult ) {
                my ( $num, $session ) = split ( /\t/, $_ );
                &universalTextPrinter( "NOHEADER", &runDsmadmc( "cancel $LastCommandType $session" ) );
            }

        }
        else {
          #wrong parameter

        }
    }
    else {

        &msg ( '0031E', "Only 'SHow Sessions' OR 'SHow PROcesses' allowed" );

    }

    return 0;

};

########
# REAch #######################################################################################################
########
&msg( '0110D', 'REAch' );
$Commands{&commandRegexp( "reach", "" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "REAch Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my $parameter = $2;

    if ( defined( $LastCommandType ) && $LastCommandType =~ m/SESSION/ && $parameter =~ m/\d+/ ) {

        my $number = $parameter;

        $number--;

        if ( $number <= $#LastResult ) {

            my ( $num, $session, $state, $wait, $sent, $received, $type, $platform, $node_name ) = split ( /\t/, $LastResult[$number] );

            my @url = &runTabdelDsmadmc( "select URL from NODES where NODE_NAME='".$node_name."'" );

            if ( ! defined ( $url[0] ) || $url[0] eq '' ) {

                &msg ( '0050E', $node_name );

            }
            else {

                &reach ( $url[0] );

            }

        }
        elsif ( $number > $#LastResult ) {

            &msg ( '0032E' ); # out of range

        }
        else {

            &msg ( '0031E', "Only 'SHow Sessions' allowed" );

        }
    }
    elsif ( $parameter =~ m/\w+/ ) {

        my $node_name = uc( $parameter );

        print "[$node_name]\n";

        my @url = &runTabdelDsmadmc( "select URL from NODES where NODE_NAME='".$node_name."'" );

        if ( ! defined ( $url[0] ) || $url[0] eq '' ) {

                &msg ( '0050E', $node_name );

            }
            else {

                &reach ( $url[0] );

            }

    }
    else {

        &msg ( '0030E' );

    }


    return 0;

};

##############
# Show DISks ###########################################################################################################
##############
&msg( '0110D', 'SHow DISks' );
$Commands{&commandRegexp( "show", "disks" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow DISks Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @query = grep( /DISK/, &runTabdelDsmadmc( "select STGPOOL_NAME,DEVCLASS,EST_CAPACITY_MB,PCT_UTILIZED,PCT_MIGR,HIGHMIG,LOWMIG,NEXTSTGPOOL from STGPOOLS", 'select_x_from_stgpools' ) );
    return if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'GENERAL';

    my @printable;

    foreach ( deleteColumn( 1, @query ) ) {
      my @line = split ( /\t/ );
      $line[1] = &byteFormatter ( $line[1], 'MB' );
      $line[6] = " " if ( ! defined ( $line[6] ) );
      push ( @printable, join( "\t", $line[0], $line[1], $line[2], $line[3], $line[4], $line[5], $line[6] ) );
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tStgPoolName\tEstCap{RIGHT}\tPctUtil{RIGHT}\tPctMig{RIGHT}\tHigh{RIGHT}\tLow{RIGHT}\tNextStgPool", &addLineNumbers( @printable ) );

    return 0;

};
&defineAlias( 'dsk',    'show disks' );
&defineAlias( 's dsk',  'show disks' );
&defineAlias( 'sh dsk', 'show disks' );

#################
# Show STGpools ###########################################################################################################
#################
&msg( '0110D', 'SHow STGpools' );
$Commands{&commandRegexp( "show", "stgpools" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow STGpools Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @query = &runTabdelDsmadmc( "select STGPOOL_NAME,DEVCLASS,EST_CAPACITY_MB,PCT_UTILIZED,PCT_MIGR,HIGHMIG,LOWMIG,NEXTSTGPOOL from STGPOOLS", 'select_x_from_stgpools' );
    return if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'GENERAL';

    my @printable;

    foreach ( @query ) {
      my @line = split ( /\t/ );
      $line[2] = &byteFormatter ( $line[2], 'MB' );
      $line[4] = " " if ( ! defined ( $line[4] ) );
      $line[5] = " " if ( ! defined ( $line[5] ) );
      $line[6] = " " if ( ! defined ( $line[6] ) );
      $line[7] = " " if ( ! defined ( $line[7] ) );
      push ( @printable, join( "\t", $line[0], $line[1], $line[2], $line[3], $line[4], $line[5], $line[6], $line[7] ) );
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tStgPoolName\tDeviceClass\tEstCap{RIGHT}\tPctUtil{RIGHT}\tPctMig{RIGHT}\tHigh{RIGHT}\tLow{RIGHT}\tNextStgPool", &addLineNumbers( @printable ) );

    return 0;

};
&defineAlias( 'stgp',    'show stgp' );
&defineAlias( 's stgp',  'show stgp' );
&defineAlias( 'sh stgp', 'show stgp' );

###############
# Show DRIVes ##########################################################################################################
###############
&msg( '0110D', 'SHow DRIves' );
$Commands{&commandRegexp( "show", "drives" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow DRIves Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'DRIVE';

    my @query = &runTabdelDsmadmc( "select LIBRARY_NAME,DRIVE_NAME,'online='||ONLINE,ELEMENT,DRIVE_STATE,DRIVE_SERIAL,'['||VOLUME_NAME||']' from drives" );
    return if ( $#query < 0 || $LastErrorcode );

    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tLibraryName\tDriveName\tOnline\tElement\tState\tSerial\tVolume", &addLineNumbers( @query ) );

    return 0;

};
&defineAlias( 's drive', 'show drives' );

########################################################################################################################

##############
# Show PAThs ###########################################################################################################
##############
&msg( '0110D', 'SHow PAThs' );
$Commands{&commandRegexp( "show", "paths" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow PAThs Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'PATH';

    my @query = &runTabdelDsmadmc( "select SOURCE_NAME,DESTINATION_NAME,'srct='||SOURCE_TYPE,'destt='||DESTINATION_TYPE,LIBRARY_NAME,'device='||DEVICE,'online='||ONLINE from paths where LIBRARY_NAME is null" );
    return if ( $LastErrorcode );

    push ( @query, &runTabdelDsmadmc( "select SOURCE_NAME,DESTINATION_NAME,'srct='||SOURCE_TYPE,'destt='||DESTINATION_TYPE,'library='||LIBRARY_NAME,'device='||DEVICE,'online='||ONLINE from paths where LIBRARY_NAME is not null" ) );
    return if ( $#query < 0 || $LastErrorcode );

    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tSourceName\tDestinationName\tSourceType\tDestinationType\tLibraryName\tDevice\tOnline", &addLineNumbers( @query ) );

    return 0;

};
&defineAlias( 's path', 'show path' );

########################################################################################################################

##########
# ONline ################################################################################################################
##########
&msg( '0110D', 'ONLine' );
$Commands{&commandRegexp( "online", "" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "ONLine Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my $number = $2;

    if ( $number eq '' ) {
        &msg ( '0030E' );
        return 0;
    }

    $number--;

    if ( defined( $LastCommandType ) && $LastCommandType =~ m/DRIVE|PATH/ && $number <= $#LastResult ) {

        my @line = split ( /\t/, $LastResult[$number] );

        &setSimpleTXTOutput();
        &universalTextPrinter( "NOHEADER", &runDsmadmc( "update path  $line[1] $line[2] $line[3] $line[4] $line[5] online=yes") ) if ( $LastCommandType eq 'PATH' );
        &universalTextPrinter( "NOHEADER", &runDsmadmc( "update drive $line[1] $line[2] online=yes" ) )                           if ( $LastCommandType eq 'DRIVE' );

    }
    elsif ( $number > $#LastResult ) {

        &msg ( '0032E' ); # out of range

    }
    else {

        &msg ( '0031E', "Only 'SHow PAThs' OR 'SHow DRIves' allowed" );

    }

    return 0;

};
&defineAlias( 'on', 'online' );

########################################################################################################################

###########
# OFFline ##############################################################################################################
###########
&msg( '0110D', 'OFFline' );
$Commands{&commandRegexp( "offline", "" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "OFFline Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my $number = $2;

    if ( $number eq '' ) {
        &msg ( '0030E' );
        return 0;
    }

    $number--;

    if ( defined( $LastCommandType ) && $LastCommandType =~ m/DRIVE|PATH/ && $number <= $#LastResult ) {

        my @line = split ( /\t/, $LastResult[$number] );

        &setSimpleTXTOutput();
        &universalTextPrinter( "NOHEADER", &runDsmadmc( "update path  $line[1] $line[2] $line[3] $line[4] $line[5] online=no" ) ) if ( $LastCommandType eq 'PATH' );
        &universalTextPrinter( "NOHEADER", &runDsmadmc( "update drive $line[1] $line[2] online=no" ) )                            if ( $LastCommandType eq 'DRIVE' );

    }
    elsif ( $number > $#LastResult ) {

        &msg ( '0032E' ); # out of range

    }
    else {

        &msg ( '0031E', "Only 'SHow PAThs' OR 'SHow DRIves' allowed" );

    }

    return 0;

};
&defineAlias( 'of', 'offline' );

########################################################################################################################

#################
# STart DSMadmc ###########################################################################################################
#################
&msg( '0110D', 'STart DSMadmc' );
$Commands{&commandRegexp( "start", "dsmadmc" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "STart DSMadmc Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'GENERAL';

    if ( $3 =~ m/(nologin|no)/i ) {
        &startDsmadmc( );
    }
    else {
        &startDsmadmc( 'AUTOLOGIN' );
    }

    return 0;

};
&defineAlias( 'dsm', 'start dsmadmc' );

###############
# SHow EVEnts ##########################################################################################################
###############
&msg( '0110D', 'SHow EVEnts' );
$Commands{&commandRegexp( "show", "events" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow EVEnts Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'EVENTS';

    my @query = &runTabdelDsmadmc('q event * * begind=-1 begint=07:00 endd=today endt=now f=d '.$3.' '.$4.' '.$5);
    return if ( $#query < 0 );

    @query = deleteColumn( 8, @query);

    &pbarInit( "PREPARATION |", scalar( @query ), "|");

    my $i = 1;
    my @printable;
    foreach ( @query ) {
        my @line = split(/\t/);

        $line[7] = '' if  ( ! defined ( $line[7] ) );

        if ( $line[3] =~ m/(\d\d\/\d\d\/\d\d\d\d\s*)/ ) {
            my $date = $1;
            $line[4] =~ s/$date//;
            $line[5] =~ s/$date//;
        }
        
        if ( $line[6] =~ m/completed/i ) {
            if ( $line[7] == 4 || $line[7] == 8 ) {
                $line[7] = colorString( $line[7], "BOLD YELLOW" );
            }
        }
        elsif ( $line[6] =~ m/missed/i ) {
            $line[6] = colorString( $line[6], "BOLD YELLOW" );
        }
        elsif ( $line[6] =~ m/failed/i ) {
            $line[6] = colorString( $line[6], "BOLD RED" );
            $line[7] = colorString( $line[7], "BOLD RED" );
        }
        elsif ( $line[6] =~ m/severed/i ) {
            $line[6] = colorString( $line[6], "BOLD RED" );
            $line[7] = colorString( $line[7], "BOLD RED" );
        }

        push ( @printable, join( "\t", @line ) );

        &pbarUpdate( $i++ );

    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "Domain\tScheduleName\tNodeName\tScheduledStart\tActStart{RIGHT}\tCompleted{RIGHT}\tStatus\tRC", @printable );

    return 0;

};
&defineAlias( 'sh exc', 'show events exc=yes' );

########################################################################################################################

&msg( '0110D', 'SHow LIBVolumes' );
$Commands{&commandRegexp( "show", "libvolume" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "show libvolumes Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @libvolumes =
      &runTabdelDsmadmc( "select volume_name, library_name from libvolumes",
        "select_vol_lib_from_libvolumes" );
    my @volumes = &runTabdelDsmadmc(
"select volume_name, stgpool_name from volumes where devclass_name != 'DISK'"
    );

    my %tmpLibvolumeHash;

    my @tmp;

    my $i;

    # array2hash
    &pbarInit( "LIBVOLUMES |", scalar( @libvolumes ), "|");

    $i = 1;
    foreach (@libvolumes) {
        my ( $volume_name, $libarry_name ) = split( /\t/, $_ );
        $tmpLibvolumeHash{$volume_name} = $libarry_name;
        &pbarUpdate($i++);
    }

    # "join"
    &pbarInit( "VOLUMES    |", scalar( @volumes ), "|");
    $i = 1;
    my $missingString = &colorString( "!MISSING!", "BOLD RED" );
    foreach (@volumes) {
        my ( $volume_name, $stgpool_name ) = split( /\t/, $_ );
        if ( defined( $tmpLibvolumeHash{$volume_name} ) ) {
#          delete $tmpLibvolumeHash{$volume_name};
        }
        else {
            push( @tmp, "$volume_name\t$stgpool_name\t$missingString" );
        }
        &pbarUpdate( $i++ );
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "VOLUME\tSTGPOOL\tLIBRARY", @tmp );

    $LastCommandType = "GENERAL";

    return 0;

};

##################
# Show SCHedules ######################################################################################################
##################
&msg( '0110D', 'SHow SCHedules' );
$Commands{&commandRegexp( "show", "schedules" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow SCHedules Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'SCHEDULES';

    my @query = &runTabdelDsmadmc( 'q sched '.$3 );
    return if ( $#query < 0 );

    &setSimpleTXTOutput();
    &universalTextPrinter( "Domain\tScheduleName\tAction\tStartDateTime\tDuration\tPeriod\tDay", &deleteColumn( 1, @query ) );

    return 0;

};

########################################################################################################################

###################
# SHow EXPiration ######################################################################################################
###################
&msg( '0110D', 'SHow EXPiration' );
$Commands{&commandRegexp( "show", "expiration" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow EXPiration Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'EXPIRATION';

    my @query = &runTabdelDsmadmc( "select START_TIME, END_TIME-START_TIME as DURATION, SUCCESSFUL, EXAMINED, AFFECTED from Summary where ACTIVITY ='EXPIRATION'", 'select_EXPIRATION_from_summary' );
    return if ( $#query < 0 );

    my @printable;

    foreach ( @query ) {
        my $line = $_;
        $line =~ s/\.000000//g;
        push ( @printable, $line );
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "StartTime\tDuration\tSuccess\tExamined\tAffected", @printable );

    return 0;

};

########################################################################################################################

#################
# Show FILlings ########################################################################################################
#################
&msg( '0110D', 'SHow FILlings' );
my %filling_tresholds;
$Commands{&commandRegexp( "show", "fillings" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow FILlings Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

  my $stg = $3;

  my @tmpquery = &runTabdelDsmadmc( "select stgpool_name, count(*) from volumes where stgpool_name like upper\('$stg%'\) and status='FILLING' and ACCESS='READWRITE' group by STGPOOL_NAME order by 2 desc" );
  return if ( $#tmpquery < 0 );

  my @query;
  my @printable;

  my $counter = 1;

  # add the deltas
  for ( @tmpquery ) {
    my @line = split( /\t/ );

    # filling tresholds
    if ( ( $line[1] <= 1 ) || ( defined $filling_tresholds{$line[0]} && $filling_tresholds{$line[0]} >= $line[1] ) ) {
#      push (@line, '  OK');
#      push (@return, join(',', @line))
    }
    else {
      $line[1] = "$line[1]/$filling_tresholds{$line[0]}" if ( defined $filling_tresholds{$line[0]} );
      push ( @line, 'FAILED');
      push ( @printable, join( "\t", @line ) );

      for ( &runTabdelDsmadmc( "select VOLUME_NAME, PCT_UTILIZED from volumes where STGPOOL_NAME='$line[0]' and STATUS='FILLING' and ACCESS='READWRITE' order by PCT_UTILIZED" ) ) {
        my @line = split(/\t/);
        push ( @printable, " [$counter]\t\[$line[0]\] \[$line[1]\]" );
        push ( @query, join( "\t", "FAKESTRING", $line[0] ) );
        $counter++;
      }
    }

  }

  &setSimpleTXTOutput();
  &universalTextPrinter( "StgpoolName\tFillingVolume#\tResult", @printable );

  return 0;
  
};

########################################################################################################################

1;