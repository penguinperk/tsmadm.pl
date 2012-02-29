#!/usr/bin/perl

use strict;
use warnings;
use Pod::Usage;

no warnings 'redefine';

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
# SHow VOLUMEUsage #####################################################################################################
###################$
&msg( '0110D', 'SHow VOLUMEUsage' );
$Commands{&commandRegexp( "show", "volumeusage", 2, 7 )} = sub {

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

    my @query = &runTabdelDsmadmc( "select node_name, stgpool_name, count(distinct volume_name) from volumeusage group by node_name, stgpool_name order by 3 desc" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'VOLUMEUSAGE';

    &setSimpleTXTOutput();
    &universalTextPrinter( "NodeName\tStgPool\t#Volumes{RIGHT}", @query );

    return 0;

};

##########################
# SHow BACKUPPerformance #####################################################################################################
##########################
&msg( '0110D', 'SHow BACKUPPerformance' );
$Commands{&commandRegexp( "show", "backupperformance", 2, 7 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow BACKUPPerformance Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    &basicPerformanceFromSummary( 'STGPOOL BACKUP' );

    return 0;

};

############################
# SHow MOVEDATAPerformance #####################################################################################################
############################
&msg( '0110D', 'SHow MOVEDATAPerformance' );
$Commands{&commandRegexp( "show", "movedataperformance", 3, 9 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow MOVEDATAPerformance Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    &basicPerformanceFromSummary( 'MOVE DATA' );

    return 0;

};

###############################
# SHow RECLAMATIONPerformance #####################################################################################################
###############################
&msg( '0110D', 'SHow RECLAMATIONPerformance' );
$Commands{&commandRegexp( "show", "reclamationperformance", 2, 12 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow REClamationperformance Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    &basicPerformanceFromSummary( 'RECLAMATION' );

    return 0;

};

##########################
# SHow CLIBACKUPPerformance #####################################################################################################
##########################
&msg( '0110D', 'SHow CLIBACKUPPerformance' );
$Commands{&commandRegexp( "show", "clibackupperformance", 2, 10 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow BACKUPPerformance Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    &basicPerformanceFromSummary( 'BACKUP' );

    return 0;

};

sub basicPerformanceFromSummary ( $ ) {

    # ARCHIVE
    # BACKUP
    # EXPIRATION
    # FULL_DBBACKUP
    # INCR_DBBACKUP
    # MIGRATION
    # MOVE DATA
    # RECLAMATION
    # RESTORE
    # RETRIEVE
    # STGPOOL BACKUP
    # TAPE MOUNT
    
    my @query = &runTabdelDsmadmc( "select date(START_TIME),time(START_TIME),date(END_TIME),time(END_TIME),NUMBER,ENTITY,SCHEDULE_NAME,EXAMINED,AFFECTED,FAILED,BYTES,IDLE,MEDIAW,PROCESSES,SUCCESSFUL,cast((END_TIME-START_TIME) seconds as decimal) from summary where ACTIVITY='".$_[0]."' and (start_time >= current_timestamp - 1 day) and (end_time <= current_timestamp - 0 day)" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'PERFORMANCE';
    
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
        
        my $speed   = ( $line[15] > 0 ) ? int( ( $line[10]/1024/1024 ) / $line[15] )." MB/s" : "n/a";
        my $failed  = ( $line[9] > 0 ) ? &colorString( $line[9], 'BOLD RED') : $line[9];
        my $success = ( $line[14] eq 'NO' ) ? &colorString( $line[14], 'BOLD RED') : $line[14];
        
        push ( @printable, join( "\t", $line[0].' '.$line[1], $line[2].$line[3], $line[4], $line[5], $line[6], $line[7].'/'.$line[8].'/'.$failed, &byteFormatter ( $line[10], 'B' ), &timeFormatter ( $line[15], 's' ), $speed, &timeFormatter ( $line[11], 's' ), &timeFormatter ( $line[12], 's' ), $line[13], $success ) );
       
    }    
        
    &setSimpleTXTOutput();
    &universalTextPrinter( "Start\tEnd\t#Proc\tPool\tSchedName\t#E/A/F\t#Bytes{RIGHT}\tTime{RIGHT}\tSpeed{RIGHT}\tIdle{RIGHT}\tMedW{RIGHT}\tP\tSuc{RIGHT}", @printable );
    
}

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

    my @query = &runTabdelDsmadmc( 'q actlog '.$3.' '.$4.' '.$5.' '.$6.' '.$7.' '.$8 );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'ACTIVITY';
    
    my @printable;
    
    foreach ( @query ) {
        my @line = split ( /\t/ );
        push ( @printable, join( "\t", $line[0], $line[1] ));
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "Date\tActivity", @printable );
    
    return 0;
};

#######################
# SHow NODEOccuopancy ########################################################################################################
#######################
&msg( '0110D', 'SHow NODEOccuopancy' );
$Commands{&commandRegexp( "show", "nodeoccuopancy", 2, 5 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow NODEOccuopancy Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @query = &runTabdelDsmadmc( "select node_name, sum(logical_mb) , sum(num_files) from occupancy where node_name like upper('$3%')  group by node_name order by 2 desc" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'NODEOCCU';
    
    my @printable;
    
    foreach ( @query ) {
        my @line = split ( /\t/ );
        push ( @printable, join( "\t", $line[0], &byteFormatter( $line[1], 'MB'), $line[2] ) );
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tNodeName\tData{RIGHT}\tFile#{RIGHT}", &addLineNumbers( @printable ) );
    
    return 0;
};

#######################
# SHow COLumns ########################################################################################################
#######################
&msg( '0110D', 'SHow COLumns' );
$Commands{&commandRegexp( "show", "columns", 2, 3 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow COLumns Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my $tabname = $3;
   
    my @query = &runTabdelDsmadmc( "select tabname,colname,typename,length,remarks from columns where tabname like upper('%$tabname%')" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'COLUMNS';
   
    &setSimpleTXTOutput();
    &universalTextPrinter( "Table\tColumn\tType{RIGHT}\tLength{RIGHT}\tRemark", @query );
    
    return 0;
};

#######################
# SHow DBBackup ########################################################################################################
#######################
&msg( '0110D', 'SHow DBBackup' );
$Commands{&commandRegexp( "show", "dbbackup", 2, 3 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow DBBackup Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @query = &runTabdelDsmadmc( "select date(DATE_TIME),time(DATE_TIME),TYPE,BACKUP_SERIES,VOLUME_SEQ,DEVCLASS,'['||VOLUME_NAME||']' from volhistory where type='BACKUPFULL' or type='BACKUPINCR' order by BACKUP_SERIES" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'BACKUP';
   
    &setSimpleTXTOutput();
    &universalTextPrinter( "Date\tTime\tType\tSerie{RIGHT}\tSeq{RIGHT}\tDeviceClass\tVolume{RIGHT}", @query );

    return 0;
};

#######################
# SHow STAtus ########################################################################################################
#######################
&msg( '0110D', 'SHow STAtus' );
$Commands{&commandRegexp( "show", "status", 2, 3 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow STAtus Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

#    my @query = &runTabdelDsmadmc( "select node_name, sum(logical_mb) , sum(num_files) from occupancy where node_name like upper('$3%')  group by node_name order by 2 desc" );
#    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'STATUS';
   
    my @printable;

    if ( $TSMSeverStatus{VERSION} <= 5 ) {
        
        
    }
    else {
        
    }

    push ( @printable, "$TSMSeverStatus{VERSION}\t\t\t");

    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tNodeName\tData{RIGHT}\tFile#{RIGHT}", @printable );
    
    return 0;
};

1;
