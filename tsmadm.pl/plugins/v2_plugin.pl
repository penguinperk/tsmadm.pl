#!/usr/bin/perl

use strict;
use warnings;
use Pod::Usage;

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

&msg( '0110D', 'new v2 commands' );

####################
# SHow VOLumeusage #####################################################################################################
###################$
&msg( '0110D', 'SHow VOLumeusage' );
$Commands{&commandRegexp( "show", "volumeusage" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow VOLumeusage Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'VOLUMEUSAGE';

    my @query = &runTabdelDsmadmc( "select node_name, stgpool_name, count(distinct volume_name) from volumeusage group by node_name, stgpool_name order by 3 desc" );
    return if ( $#query < 0 );
        
    &setSimpleTXTOutput();
    &universalTextPrinter( "NodeName\tStgPool\t#Volumes{RIGHT}", @query );

    return 0;

};

####################
# SHow 2BAckup #####################################################################################################
###################$
&msg( '0110D', 'SHow 2BAckup' );
$Commands{&commandRegexp( "show", "2backup" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow 2BAckup Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = '?';

    my @query = &runTabdelDsmadmc( "select date(START_TIME),time(START_TIME),date(END_TIME),time(END_TIME),NUMBER,ENTITY,SCHEDULE_NAME,EXAMINED,AFFECTED,FAILED,BYTES,IDLE,MEDIAW,PROCESSES,SUCCESSFUL,cast((END_TIME-START_TIME) seconds as decimal) from summary where ACTIVITY='STGPOOL BACKUP' and (start_time >= current_timestamp - 1 day) and (end_time <= current_timestamp - 0 day)" );
    return if ( $#query < 0 );
    
    &pbarInit( "PREPARATION |", scalar( @query ), "|");

    my $i = 1;
    my @printable;
    
    foreach ( @query ) {
        my @line = split(/\t/);
        
        &pbarUpdate( $i++ );
        
        if ( $line[0] =~ m/(\d\d\d\d-\d\d-\d\d\s*)/ ) {
            
            next if ( $line[4] == 0 ); # no data
            
            my $date = $1;
            if ( $line[2] =~ s/$date// ) {
                # same day
            }
            else {
                $line[2] .= ' ';
            }
        }
        
        my $speed = int( ( $line[10]/1024/1024 ) / $line[15])." MB/s";
        
        push ( @printable, join( "\t", $line[0].' '.$line[1], $line[2].$line[3], $line[4], $line[5], $line[6], $line[7].'/'.$line[8].'/'.$line[9], &byteFormatter ( $line[10], 'B' ), &timeFormatter ( $line[15], 's' ), $speed, &timeFormatter ( $line[11], 's' ), &timeFormatter ( $line[12], 's' ), $line[13], $line[14]) );
       
    }    
        
    &setSimpleTXTOutput();
    &universalTextPrinter( "Start\tEnd\t#Proc\tPool\tSchedName\t#E/A/F\t#Bytes{RIGHT}\tTime{RIGHT}\tSpeed{RIGHT}\tIdle{RIGHT}\tMedW{RIGHT}\tP\tSuc", @printable );

    return 0;

};

#################
# SHow ACTivity ########################################################################################################
#################
&msg( '0110D', 'SHow ACTivity' );
$Commands{&commandRegexp( "show", "activity" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow ACTivity Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'ACTIVITY';

    my @query = &runTabdelDsmadmc('q actlog '.$3.' '.$4.' '.$5.' '.$6.' '.$7.' '.$8);
    return if ( $#query < 0 );
    
    my @printable;
    
    foreach ( @query ) {
        my @line = split ( /\t/ );
        push ( @printable, join( "\t", $line[0], $line[1] ));
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "Date\tActivity", @printable );
    
    return 0;
};

1;
