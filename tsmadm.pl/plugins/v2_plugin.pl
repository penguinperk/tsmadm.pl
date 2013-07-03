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

    &basicPerformanceFromSummary( 'STGPOOL BACKUP', $3, $4 );

    return 0;

};

############################
# SHow MOVEDATAPerformance #####################################################################################################
############################
&msg( '0110D', 'SHow MOVEDATAPerformance' );
$Commands{&commandRegexp( "show", "movedataperformance", 2, 9 )} = sub {

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

    &basicPerformanceFromSummary( 'MOVE DATA', $3, $4 );

    return 0;

};

############################
# SHow MIGRATIONPerformance #####################################################################################################
############################
&msg( '0110D', 'SHow MIGRATIONPerformance' );
$Commands{&commandRegexp( "show", "migrationperformance", 2, 10 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow MiGRATIONPerformance Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    &basicPerformanceFromSummary( 'MIGRATION', $3, $4 );

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

    &basicPerformanceFromSummary( 'RECLAMATION', $3, $4 );

    return 0;

};

##########################
# SHow CLIENTBACKUPPerformance #####################################################################################################
##########################
&msg( '0110D', 'SHow CLIENTBACKUPPerformance' );
$Commands{&commandRegexp( "show", "clientbackupperformance", 2, 13 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow CLIENTBACKUPPerformance Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    &basicPerformanceFromSummary( 'BACKUP', $3, $4 );

    return 0;

};

##########################
# SHow CLIENTRESTOREPerformance #####################################################################################################
##########################
&msg( '0110D', 'SHow CLIENTRESTOREPerformance' );
$Commands{&commandRegexp( "show", "clientrestoreperformance", 2, 13 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow CLIENTRESTOREPerformance Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    &basicPerformanceFromSummary( 'RESTORE', $3, $4 );

    return 0;

};

##########################
# SHow CLIENTARCHIVEPerformance #####################################################################################################
##########################
&msg( '0110D', 'SHow CLIENTARCHIVEPerformance' );
$Commands{&commandRegexp( "show", "clientarchiveperformance", 2, 13 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow CLIENTARCHIVEPerformance Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    &basicPerformanceFromSummary( 'ARCHIVE', $3, $4 );

    return 0;

};

##########################
# SHow CLIENTRETRIEVEPerformance #####################################################################################################
##########################
&msg( '0110D', 'SHow CLIENTRETRIEVEPerformance' );
$Commands{&commandRegexp( "show", "clientretrieveperformance", 2, 13 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow CLIENTRETRIEVEPerformance Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    &basicPerformanceFromSummary( 'RETRIEVE', $3, $4 );

    return 0;

};

sub basicPerformanceFromSummary ( $$$ ) {

    # ARCHIVE           Ok
    # BACKUP            Ok
    # EXPIRATION
    # FULL_DBBACKUP
    # INCR_DBBACKUP
    # MIGRATION         Ok
    # MOVE DATA         Ok
    # RECLAMATION       Ok
    # RESTORE           Ok
    # RETRIEVE          Ok
    # STGPOOL BACKUP    Ok
    # TAPE MOUNT
    
    my $activity = $_[0];
       
    my $today = $_[1];
    my $fromday = $_[2];
    
    $today = 1 if ( ! defined $today || $today eq '' );
    $fromday = 0 if ( ! defined $fromday || $fromday eq '' );
        
    my @query;
    if ( $TSMSeverStatus{VERSION} <= 5 ) {
       @query = &runTabdelDsmadmc( "select date(START_TIME),time(START_TIME),date(END_TIME),time(END_TIME),NUMBER,ENTITY,SCHEDULE_NAME,EXAMINED,AFFECTED,FAILED,BYTES,IDLE,MEDIAW,PROCESSES,SUCCESSFUL,cast((END_TIME-START_TIME) seconds as decimal) from summary where ACTIVITY='".$activity."' and (start_time >= current_timestamp - $today day) and (end_time <= current_timestamp - $fromday day)" );
    } else {
       @query = &runTabdelDsmadmc( "select date(START_TIME),time(START_TIME),date(END_TIME),time(END_TIME),NUMBER,ENTITY,SCHEDULE_NAME,EXAMINED,AFFECTED,FAILED,BYTES,IDLE,MEDIAW,PROCESSES,SUCCESSFUL,cast(timestampdiff(2,char((END_TIME-START_TIME))) as decimal) from summary where ACTIVITY='".$activity."' and (start_time >= current_timestamp - $today day) and (end_time <= current_timestamp - $fromday day)" );
    }
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'PERFORMANCE';
    
    &pbarInit( "PREPARATION |", scalar( @query ), "|");

    my $i = 1;
    my @printable;
    
    my $max = 0;
    foreach ( @query ) {
        my @line = split( /\t/ );
        
        $line[5] =~ m/(.+) ->/;
        $max = length( $1 ) if ( length( $1 ) > $max );
        
    }
    
    foreach ( @query ) {
        my @line = split( /\t/ );
        
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
        
        $line[12] = ( $line[12] > 600 ) ? &colorString( &timeFormatter ( $line[12], 's' ), 'BOLD RED') : &timeFormatter ( $line[12], 's' );
        
        $line[5] =~ m/(.+) ->/;
        $line[5] = ( ' ' x ( $max - length( $1 ) ) ).$line[5];
        
        $line[5] =~ s/(\w+) ->/\[$1\] ->/ if ( $activity eq "MOVE DATA" ) ;
        
        push ( @printable, join( "\t", $line[0].' '.$line[1], $line[2].$line[3], $line[4], $line[5], $line[6], $line[7].'/'.$line[8].'/'.$failed, &byteFormatter ( $line[10], 'B' ), &timeFormatter ( $line[15], 's' ), $speed, &timeFormatter ( $line[11], 's' ), $line[12], $line[13], $success ) );
       
    }
    
    my $columntmp = "Pool";
    if ( $activity eq "BACKUP" || $activity eq "RESTORE" || $activity eq "ARCHIVE" || $activity eq "RETRIEVE" ) {
        $columntmp = "Node";
    }
        
    &setSimpleTXTOutput();    
    &universalTextPrinter( "Start\tEnd{RIGHT}\t#Proc\t$columntmp\tSchedName\t#E/A/F\t#Bytes{RIGHT}\tTime{RIGHT}\tSpeed{RIGHT}\tIdle{RIGHT}\tMedW{RIGHT}\tP\tSuc{RIGHT}", @printable );
    
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

    # prepare options for Getopt
    my $errorsFlag;
    my $warningsFlag;
    #
    my %commandlineParameters = ( "errors"              => \$errorsFlag,
                                  "warnings"            => \$warningsFlag,
                                );

    my @myopts = ( $3,$4,$5,$6,$7,$8 );

    if ( !GetOptionsFromArray( \@myopts, %commandlineParameters ) ) {
      print "GetOptionsFromArray Error!\n";
    }
      
    GetOptionsFromArray( \@myopts, %commandlineParameters );    
    
    my @query;
    if ( ( defined ( $errorsFlag ) && $errorsFlag ne '' ) || ( defined ( $warningsFlag ) && $warningsFlag ne '' ) ) {
        
        if ( $errorsFlag ) {
            @query = &runTabdelDsmadmc( 'q actlog search=ANR????E '.join( ' ', @myopts ) );
        }
        
        if ( $warningsFlag ) {
            @query = ( @query, &runTabdelDsmadmc( 'q actlog search=ANR????W '.join( ' ', @myopts ) ) );
        }
    
        @query = sort ( grep ( !/QUERY ACTLOG search=ANR/, @query ) );
        
    }
    else {
      @query = &runTabdelDsmadmc( 'q actlog '.join( ' ', @myopts ) );
    }
    
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

    my @query = &runTabdelDsmadmc( "select node_name, type, sum(logical_mb), sum(num_files) from occupancy where node_name like upper('$3%') group by node_name,type order by 1,2 desc" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'NODEOCCU';
    
    my @printable;
    my $nodename = "";

    foreach ( @query ) {
        my @line = split ( /\t/ );
        
        my @perviousline;
        @perviousline = split ( /\t/, $printable[$#printable] ) if ( defined ( $printable[$#printable] ) ); # get the last line
        
        if ( defined ( $perviousline[0] ) && $perviousline[0] eq $line[0] && $line[1] eq "Arch" ) {
          $printable[$#printable] = join( "\t", $printable[$#printable], $line[2], $line[3] );
        }
        elsif ( $line[1] eq "Bkup" ) {
          push ( @printable, join( "\t", $line[0], $line[2], $line[3] ) );
        }
        elsif ( $line[1] eq "Arch" ) {
          push ( @printable, join( "\t", $line[0], , ,$line[2], $line[3] ) );
        }
        
    }
    
    my @printable2;
    foreach ( @printable ) {
        my @line = split ( /\t/ );
        
        $line[1] = 0 if ( ! defined( $line[1] ) );
        $line[2] = 0 if ( ! defined( $line[2] ) );
        $line[3] = 0 if ( ! defined( $line[3] ) );
        $line[4] = 0 if ( ! defined( $line[4] ) );

        my $sumData = $line[1] + $line[3];
        my $sumFiles = $line[2] + $line[4];

        push ( @printable2, join( "\t", $line[0], ( $line[1] > 0 ) ? &byteFormatter( $line[1], 'MB') : "", ( $line[2] > 0 ) ? $line[2] : "", ( $line[3] > 0 ) ? &byteFormatter( $line[3], 'MB') : "", ( $line[4] > 0 ) ? $line[4] : "", $sumData, ( $sumFiles > 0 ) ? $sumFiles : "" ) );

    }

    my @printable3;
    foreach ( sort { (split "\t", $a)[5] <=> (split "\t", $b)[5] } @printable2 ) {
        my @line = split ( /\t/ );
        
        push ( @printable3, join( "\t", $line[0], $line[1], $line[2], $line[3], $line[4], ( $line[5]> 0 ) ? &byteFormatter( $line[5], 'MB') : "", $line[6] ) );
        
    }
    
    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tNodeName\tBData{RIGHT}\tBFile#{RIGHT}\tAData{RIGHT}\tAFile#{RIGHT}\tSumData{RIGHT}\tSumFile#{RIGHT}", &addLineNumbers( @printable3 ) );
  
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

    my @query = &runTabdelDsmadmc( "select date(DATE_TIME),time(DATE_TIME),TYPE,BACKUP_SERIES,BACKUP_OPERATION,VOLUME_SEQ,DEVCLASS,VOLUME_NAME from volhistory where type='BACKUPFULL' or type='BACKUPINCR' order by BACKUP_SERIES" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'BACKUP';
   
    my @printable;

    foreach ( @query ) {
        my @line = split ( /\t/ );

        if ( $line[2] eq 'BACKUPFULL' ) {
            $line[2] = &colorString( $line[2], "BOLD GREEN");
        }
        
        $line[7] = &colorString( $line[7], "BOLD GREEN");

        push ( @printable, join( "\t", @line ) )
    }   
   
    &setSimpleTXTOutput();
    &universalTextPrinter( "Date\tTime\tType\tSerie{RIGHT}\t#{RIGHT}\tSeq{RIGHT}\tDeviceClass\tVolume{RIGHT}", @printable );

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

    return 0 if ( ! defined ( $TSMSeverStatus{"VERSION"} ) );

    $LastCommandType = 'STATUS';
   
    my @query;
    my @printable;

    my $DBMAX = 90;
    my $DBHITMIN = 99;
    
    my $LOGMAX = 60;
    #
    my $FULLDB = 2;
    
    my $DBLASTHOUR = 2;
    my $DBLASTFULLHOUR = 24;
    
    my $DBerrorcollector = 0;

    if ( $TSMSeverStatus{VERSION} <= 5 ) {

        # DB v5
        push ( @printable, "DB\t\t");
        @query = &runTabdelDsmadmc( "select AVAIL_SPACE_MB, PCT_UTILIZED, CACHE_HIT_PCT, hour(current_timestamp-LAST_BACKUP_DATE) from db" );
        return 0 if ( $#query < 0 || $LastErrorcode );
        
        my ( $dbAvailableSpace, $dbPctUtil, $dbCacheHitPct, $dbLastBackupHour ) = ( split( /\t/, $query[0] ) );

        my $DBUtilStatus = "  Ok";
        if ( $dbPctUtil > $DBMAX ) {
            $DBUtilStatus = &colorString( "Failed!", "BOLD RED");
            $DBerrorcollector++;
        }
        push ( @printable, " PctUtil\t$dbPctUtil%\t$DBUtilStatus") if ( defined $dbPctUtil );

        my $DBCacheStatus = "  Ok";
        if ( $dbCacheHitPct < $DBHITMIN ) {
            $DBCacheStatus = &colorString( "Failed!", "BOLD RED");
            $DBerrorcollector++;
        }
        push ( @printable, " Cache Hit\t$dbCacheHitPct%\t$DBCacheStatus") if ( defined $dbCacheHitPct );

        my $DBBackupStatus = "  Ok";
        if ( $dbLastBackupHour > $DBLASTHOUR ) {
            $DBBackupStatus = &colorString( "Failed!", "BOLD RED");
            $DBerrorcollector++;
        }
        $dbLastBackupHour = &timeFormatter ( $dbLastBackupHour, "H" );
        push ( @printable, " Last DBBackup\t$dbLastBackupHour\t$DBBackupStatus") if ( defined $dbLastBackupHour );
    
        #@query = &runTabdelDsmadmc( "select '['||VOLUME_NAME||']', BACKUP_SERIES, hour(current_timestamp-DATE_TIME) from volhistory where type='BACKUPFULL' order by BACKUP_SERIES desc" );
        @query = &runTabdelDsmadmc( "select VOLUME_NAME, BACKUP_SERIES, hour(current_timestamp-DATE_TIME) from volhistory where type='BACKUPFULL' order by BACKUP_SERIES desc" );
        return 0 if ( $#query < 0 || $LastErrorcode );
        
        my ( $DBLastFull, $dbLastSeq, $dbLastFullBackupHour ) = ( split( /\t/, $query[0] ) );
        
        my $DBFullBackupStatus = "  Ok";
        if ( $dbLastFullBackupHour > $DBLASTFULLHOUR ) {
            $DBFullBackupStatus = &colorString( "Failed!", "BOLD RED");
            $DBerrorcollector++;
        }
        $dbLastFullBackupHour = &timeFormatter ( $dbLastFullBackupHour, "H" );
        push ( @printable, " Last Full DBBackup\t$dbLastFullBackupHour\t$DBFullBackupStatus") if ( defined $dbLastFullBackupHour );
        
        push ( @printable, " Last Full Volume\t$DBLastFull\t") if ( defined $DBLastFull );
    
        if ( $DBerrorcollector > 0 ) {
            push ( @printable, " Status\t  =>\t".&colorString( "Failed!", "BOLD RED"));
        }
        else {
            push ( @printable, " Status\t=> \t [OK]");
        }
        push ( @printable, "\t\t" );   
        
        # LOG v5
        push ( @printable, "LOG\t\t");
        my $LOGerrorcollector = 0;
        @query = &runTabdelDsmadmc( "select PCT_UTILIZED, MAX_PCT_UTILIZED from log" );
        return 0 if ( $#query < 0 || $LastErrorcode );
        
        my ( $logPctUtil, $logMaxPctUtil ) = ( split( /\t/, $query[0] ) );
        
        my $LOGUtilStatus = "  Ok";
        if ( $logPctUtil > $LOGMAX ) {
            $LOGUtilStatus = &colorString( "Failed!", "BOLD RED");
            $LOGerrorcollector++;
        }
        push ( @printable, " PctUtil\t$logPctUtil%\t$LOGUtilStatus");
        
        my $LOGMaxStatus = "  Ok";
        if ( $logMaxPctUtil > $LOGMAX ) {
            $LOGMaxStatus = &colorString( "Failed!", "BOLD RED");
            $LOGerrorcollector++;
        }
        push ( @printable, " MaxPct\t$logMaxPctUtil%\t$LOGMaxStatus");
        
        if ( $LOGerrorcollector > 0 ) {
            push ( @printable, " Status\t=> \t".&colorString( "Failed!", "BOLD RED"));
        }
        else {
            push ( @printable, " Status\t=>\t [OK]");
        }
        
    }
    else {
        
        # DB v6
        push ( @printable, "DB\t\t");
        @query = &runTabdelDsmadmc( "select FREE_SPACE_MB, BUFF_HIT_RATIO, PKG_HIT_RATIO, hour(current_timestamp-LAST_REORG), hour(current_timestamp-LAST_BACKUP_DATE) from db" );
        return 0 if ( $#query < 0 || $LastErrorcode );
        
        my ( $dbFreeSpace, $dbCacheHitPct, $dbPkgHitPct, $dbLastReorgHour, $dbLastBackupHour ) = ( split( /\t/, $query[0] ) );
        
        $dbFreeSpace = &byteFormatter ( $dbFreeSpace, 'MB' );
        push ( @printable, " FreeSpace\t$dbFreeSpace\t");

        my $DBCacheStatus = "  Ok";
        if ( $dbCacheHitPct < $DBHITMIN ) {
            $DBCacheStatus = &colorString( "Failed!", "BOLD RED");
            $DBerrorcollector++;
        }
        push ( @printable, " Cache Hit\t$dbCacheHitPct%\t$DBCacheStatus") if ( defined $dbCacheHitPct );
        
        my $DBPkgStatus = "  Ok";
        if ( $dbPkgHitPct < $DBHITMIN ) {
            $DBPkgStatus = &colorString( "Failed!", "BOLD RED");
            $DBerrorcollector++;
        }
        push ( @printable, " Pkg Hit\t$dbPkgHitPct%\t$DBPkgStatus") if ( defined $dbPkgHitPct );

        my $DBBackupStatus = "  Ok";
        if ( $dbLastBackupHour > $DBLASTHOUR ) {
            $DBBackupStatus = &colorString( "Failed!", "BOLD RED");
            $DBerrorcollector++;
        }
        $dbLastBackupHour = &timeFormatter ( $dbLastBackupHour, "H" );
        push ( @printable, " Last DBBackup\t$dbLastBackupHour\t$DBBackupStatus") if ( defined $dbLastBackupHour );
    
        @query = &runTabdelDsmadmc( "select '['||VOLUME_NAME||']', BACKUP_SERIES, hour(current_timestamp-DATE_TIME) from volhistory where type='BACKUPFULL' order by BACKUP_SERIES desc" );
        return 0 if ( $#query < 0 || $LastErrorcode );
        
        my ( $DBLastFull, $dbLastSeq, $dbLastFullBackupHour ) = ( split( /\t/, $query[0] ) );
        
        my $DBFullBackupStatus = "  Ok";
        if ( $dbLastFullBackupHour > $DBLASTFULLHOUR ) {
            $DBFullBackupStatus = &colorString( "Failed!", "BOLD RED");
            $DBerrorcollector++;
        }
        $dbLastFullBackupHour = &timeFormatter ( $dbLastFullBackupHour, "H" );
        push ( @printable, " Last Full DBBackup\t$dbLastFullBackupHour\t$DBFullBackupStatus") if ( defined $dbLastFullBackupHour );
        
        push ( @printable, " Last Full Volume\t$DBLastFull\t") if ( defined $DBLastFull );

        if ( $DBerrorcollector > 0 ) {
            push ( @printable, " Status\t  =>\t".&colorString( "Failed!", "BOLD RED"));
        }
        else {
            push ( @printable, " Status\t=> \t [OK]");
        }
        push ( @printable, "\t\t" );   
        
        # LOG v6
        push ( @printable, "LOG\t\t");
        my $LOGerrorcollector = 0;
        @query = &runTabdelDsmadmc( "select FREE_SPACE_MB, ACTIVE_LOG_DIR, ARCH_LOG_DIR, MIRROR_LOG_DIR, AFAILOVER_LOG_DIR from log" );
        return 0 if ( $#query < 0 || $LastErrorcode );
        
        my ( $logFreeSpace, $logActLogDir, $logArchLogDir, $logMirrorDir, $logArchFailLog ) = ( split( /\t/, $query[0] ) );
        
        $logFreeSpace = &byteFormatter ( $logFreeSpace, 'MB' );
        push ( @printable, " FreeSpace\t$logFreeSpace\t");
        push ( @printable, " ActiveLog\t$logActLogDir\t");
        push ( @printable, " ArchiveLog\t$logArchLogDir\t");
        push ( @printable, " ActiveMirror\t$logMirrorDir\t");
        push ( @printable, " ArchiveLogFail\t$logArchFailLog\t");
        
        if ( $LOGerrorcollector > 0 ) {
            push ( @printable, " Status\t=> \t".&colorString( "Failed!", "BOLD RED"));
        }
        else {
            push ( @printable, " Status\t=>\t [OK]");
        }
        
    }
    push ( @printable, "\t\t" );

    push ( @printable, "VOLs\t\t");
    # READ-ONLY volumes
    @query = &runTabdelDsmadmc( "select count(*) from volumes" );
    my $AllVolumes = ( defined $query[0] ) ? $query[0] : '0';
    
    @query = &runTabdelDsmadmc( "select count(*) from volumes where access like '%READO%'" );
    return 0 if ( $LastErrorcode );
    
    my $ReadOnlyStatus = "  Ok";
    $query[0] = 0 if (! defined $query[0] );
    if ( $query[0] > 0 ) {
        $ReadOnlyStatus = &colorString( "Failed!", "BOLD RED");
    }
    push ( @printable, " ReadOnly Vol(s)\t$AllVolumes/$query[0]\t$ReadOnlyStatus" );
    
    # UNAVAILABLE volumes
    @query = &runTabdelDsmadmc( "select count(*) from volumes where access like '%UNAVA%'" );
    return 0 if ( $LastErrorcode );
    
    my $UnavaStatus = "  Ok";
    $query[0] = 0 if ( ! defined $query[0] );
    if ( $query[0] > 0 ) {
        $UnavaStatus = &colorString( "Failed!", "BOLD RED");
    }
    push ( @printable, " Unavailable Vol(s)\t$AllVolumes/$query[0]\t$UnavaStatus" );
    
    # SUSPICIOUS volumes
    @query = &runTabdelDsmadmc( "select count(*) from volumes where WRITE_ERRORS>0 or READ_ERRORS>0" );
    return 0 if ( $LastErrorcode );
    
    my $SusStatus = "  Ok";
    $query[0] = 0 if ( ! defined $query[0] );
    if ( $query[0] > 0 ) {
        $SusStatus = &colorString( "Warning!", "BOLD YELLOW" );
    }
    push ( @printable, " Suspicious Vol(s)\t$AllVolumes/$query[0]\t$SusStatus" );
  
    push ( @printable, "\t\t" );
  
    push ( @printable, "HW\t\t");  
    # DRIVES
    @query = &runTabdelDsmadmc( "select count(*) from drives" );
    return 0 if ( $LastErrorcode );
    
    my $OnlineDrives = ( defined $query[0] ) ? $query[0] : '0';
    
    @query = &runTabdelDsmadmc( "select count(*) from drives where online='NO'" );
    return 0 if ( $LastErrorcode );
    
    my $DriveStatus = "  Ok";
    $query[0] = 0 if ( ! defined $query[0] );
    if ( $query[0] > 0 ) {
      $DriveStatus = &colorString( "Failed!", "BOLD RED")." /* Use 'show drives' command! */";
    }
    push ( @printable, " Offline Drive(s)\t$OnlineDrives/$query[0]\t$DriveStatus");
    # PATHS
    @query = &runTabdelDsmadmc( "select count(*) from paths");
    return 0 if ( $LastErrorcode );
    
    my $OnlinePaths = ( defined $query[0] ) ? $query[0] : '0';
    @query = &runTabdelDsmadmc( "select count(*) from paths where online='NO'");
    return 0 if ( $LastErrorcode );
    
    my $PathStatus = "  Ok";
    $query[0] = 0 if ( ! defined $query[0] );
    if ( $query[0] > 0 ) {
      $PathStatus = &colorString( "Failed!", "BOLD RED")." /* Use 'show path' command! */";
    }
    push ( @printable, " Offline Path(s)\t$OnlinePaths/$query[0]\t$PathStatus");

    push ( @printable, "\t\t" );

    # EVENTS
    push ( @printable, "<24 H Client Event Summary\t\t");
    @query = &runTabdelDsmadmc( "select result, count(1) from events where status='Completed' and SCHEDULED_START>'2012-01-01 00:00:00' and (SCHEDULED_START>=current_timestamp-24 hour) and DOMAIN_NAME is not null and NODE_NAME is not null group by result" );
    
    foreach ( @query ) {
        my @line = split(/\t/);
        
        if ( $line[0] eq 0 ) {
            push ( @printable, " Completed and result \[$line[0]\]\t$line[1]\t  Ok" );
        }
        elsif ( $line[0] eq 4 || $line[0] eq 8 ) {
            push ( @printable, " Completed and result \[$line[0]\]\t$line[1]\t".&colorString( "Warning!", "BOLD YELLOW" ) );
        }
        else {
            push ( @printable, " Completed and result \[$line[0]\]\t$line[1]\t".&colorString( "Failed!", "BOLD RED") );
        }
        
    }

    @query = &runTabdelDsmadmc( "select count(1) from events where status='Missed' and SCHEDULED_START>'2012-01-01 00:00:00' and (SCHEDULED_START>=current_timestamp-24 hour) and DOMAIN_NAME is not null and NODE_NAME is not null" );
    my $MissedEvents = ( defined $query[0] ) ? $query[0] : '0';
   
    if ( $MissedEvents eq 0 ) {
        push ( @printable, " Missed\t$MissedEvents\t  Ok" );
    }
    else {
        push ( @printable, " Missed\t$MissedEvents\t".&colorString( "Failed!", "BOLD RED") );
    }
    
    @query = &runTabdelDsmadmc( "select count(1) from events where status='Failed' and SCHEDULED_START>'2012-01-01 00:00:00' and (SCHEDULED_START>=current_timestamp-24 hour) and DOMAIN_NAME is not null and NODE_NAME is not null" );
    my $FailedEvents = ( defined $query[0] ) ? $query[0] : '0';
   
    if ( $FailedEvents eq 0 ) {
        push ( @printable, " Failed\t$FailedEvents\t  Ok" );
    }
    else {
        push ( @printable, " Failed\t$FailedEvents\t".&colorString( "Failed!", "BOLD RED") );
    }
    push ( @printable, "\t\t" );
    
    push ( @printable, "<24 H Admin Event Summary\t\t");
    @query = &runTabdelDsmadmc( "select result, count(1) from events where status='Completed' and SCHEDULED_START>'2012-01-01 00:00:00' and (SCHEDULED_START>=current_timestamp-24 hour) and DOMAIN_NAME is null and NODE_NAME is null group by result" );
    
    foreach ( @query ) {
        my @line = split( /\t/ );
        
        if ( $line[0] eq 0 ) {
            push ( @printable, " Completed and result \[$line[0]\]\t$line[1]\t  Ok" );
        }
        elsif ( $line[0] eq 4 || $line[0] eq 8 ) {
            push ( @printable, " Completed and result \[$line[0]\]\t$line[1]\t".&colorString( "Warning!", "BOLD YELLOW" ) );
        }
        else {
            push ( @printable, " Completed and result \[$line[0]\]\t$line[1]\t".&colorString( "Failed!", "BOLD RED" ) );
        }
        
    }

    @query = &runTabdelDsmadmc( "select count(1) from events where status='Missed' and SCHEDULED_START>'2012-01-01 00:00:00' and (SCHEDULED_START>=current_timestamp-24 hour) and DOMAIN_NAME is null and NODE_NAME is null" );
    $MissedEvents = ( defined $query[0] ) ? $query[0] : '0';
   
    if ( $MissedEvents eq 0 ) {
        push ( @printable, " Missed\t$MissedEvents\t  Ok" );
    }
    else {
        push ( @printable, " Missed\t$MissedEvents\t".&colorString( "Failed!", "BOLD RED" ) );
    }
    
    @query = &runTabdelDsmadmc( "select count(1) from events where status='Failed' and SCHEDULED_START>'2012-01-01 00:00:00' and (SCHEDULED_START>=current_timestamp-24 hour) and DOMAIN_NAME is null and NODE_NAME is null" );
    $FailedEvents = ( defined $query[0] ) ? $query[0] : '0';
   
    if ( $FailedEvents eq 0 ) {
        push ( @printable, " Failed\t$FailedEvents\t  Ok" );
    }
    else {
        push ( @printable, " Failed\t$FailedEvents\t".&colorString( "Failed!", "BOLD RED" ) );
    }    
    
    push ( @printable, "\t\t" );

    # ACTLOG
    push ( @printable, "<24 H Activity Summary\t\t");
    @query = &runTabdelDsmadmc( "select severity,count(1) from actlog where (DATE_TIME>=current_timestamp-24 hour) and severity in ('E','W') and MSGNO not in (2034) group by severity" );
    
    foreach ( @query ) {
        my @line = split( /\t/ );
        
        if ( $line[0] eq 'W' ) {
            push ( @printable, " Warnings\t$line[1]\t".&colorString( "Warning!", "BOLD YELLOW" ) );
        }
        elsif ( $line[0] eq 'E' ) {
            push ( @printable, " Errors\t$line[1]\t".&colorString( "Failed!", "BOLD RED" ) );
        }
        
    }    
    
    &setSimpleTXTOutput();
    &universalTextPrinter( "Item\tValue{RIGHT}\tResult", @printable );
    
    return 0;
};
&defineAlias( 'status', 'show status' );

#######################
# SHow LICences ########################################################################################################
#######################
&msg( '0110D', 'SHow LICences' );
my %PVU_licensing = &loadFileToHash( File::Spec->canonpath( "$Dirname/plugins/ProcessorValueUnit_licensing.txt" ) );
$Commands{&commandRegexp( "show", "LICences", 2, 3 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow LICences Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'LICENCES';

    my @query;
    my @printable;

    my $csv = ( defined( $3 ) && lc( $3 ) eq "csv" ) ? "YES" : "NO";
    my $justcpu = ( defined( $3 ) && lc( $3 ) eq "justcpu" ) ? "YES" : "NO";
      
    # Servers
    @query = &runTabdelDsmadmc( "select '!SERVER!',SERVER_NAME,HL_ADDRESS,DESCRIPTION,date(days(CURRENT_DATE))-date(LASTACC_TIME) from servers where LOCKED='NO'" );
      
    # Clients
    push ( @query, &runTabdelDsmadmc( "select PLATFORM_NAME,NODE_NAME,TCP_ADDRESS,CONTACT,date(days(CURRENT_DATE))-date(LASTACC_TIME) from nodes where LOCKED='NO' order by PLATFORM_NAME" ) );
      
    foreach my $i ( @query ) {
        my @line = split( /\t/, $i );
    
        my $PVU = 0;
        my $remark = "";
    
        if ( $line[3] =~ m/\[(\w*):*(\d*\.*\d*):*(\d*\.*\d*)\]/ ) {
            my $CPU_Type   = ( $1 ne "" ) ? uc( $1 ) : "default";
            my $CPU_Number = ( $2 ne "" ) ? $2 : 1;
            my $CPU_Core   = $3;
    
          if ( $CPU_Type eq "NOCPU" ) {
            $PVU = 0;
            $remark = "PVU NOT needed.";
          }
          elsif ( $CPU_Type eq "ARCHIVE" ) {
            $PVU = 0;
            $remark = "PVU NOT needed. ARCHIVE DATA ONLY!";
          }
          elsif ( $CPU_Type eq "CLUSTER" ) {
            $PVU = 0;
            $remark = "PVU NOT needed. Cluster resource!";
          }
          elsif ( $CPU_Type eq "SERVER" ) {
            $PVU = 0;
            $remark = "PVU NOT needed. ";
          }
          elsif ( $CPU_Type eq "VMS" ) {
            $PVU = 0;
            $remark = "PVU NOT needed. VMS with ABC client!";
          }
          elsif ( $CPU_Type eq "VMGUEST" ) {
            $PVU = 0;
            $remark = "PVU NOT needed. VM guest!";
          }
          elsif ( $CPU_Type eq "ILMT" ) {
            $PVU = 0;
            $remark = "PVU NOT needed. ILMT counts it!";
          }
          elsif ( defined $PVU_licensing{$CPU_Type} ) {
            if ( $PVU_licensing{$CPU_Type} =~ m/(\d+)\s*\*\s*(\d+)/i ) {
    
               my $core = $1;
               my $PVUpercore = $2;
    
              $CPU_Core = ( $CPU_Core ne "" ) ? $CPU_Core : $core;
              $remark = "Worng core [$CPU_Core] specified! Only [$0] allowed." if ( $CPU_Core ne $core );
    
              $PVU = $CPU_Number * $CPU_Core * $PVUpercore ;
              
              $remark = "PVU calculation is OK."
              
            }
          }
          else {
            $PVU = "n/a";
            $remark = "CPU type [$CPU_Type] not found!"
          }
        }
        else {
          $PVU = "n/a";
          $remark = &colorString( "No CPU definition!", , "BOLD RED" );
        }
        
        # highlight
        if ( $line[3] =~ /\[(.+)\]/ ) {
            my $colored = &colorString( "$1", "BOLD GREEN" );
            if ( $justcpu eq "YES" ) {
                $line[3] =~ s/.*\[.+\].*/\[$colored\]/;
            }
            else {
                $line[3] =~ s/\[.+\]/\[$colored\]/;
            }
        }
        
        push( @printable, "$line[0]\t$line[1]\t$line[2]\t$line[4]\t$PVU\t$remark\t$line[3]" );
        
    }
  
    if ( $csv eq "NO" ) {
        setSimpleTXTOutput();
        &universalTextPrinter( "PLATFORM\tNODENAME\tIPADDRESS\tLASTACCESS\tPVU\tREMARK\tCONTACT", @printable );
    }
    else {
      for ( @printable ) {
        my @line = split( /\t/ );
        print "$line[1],$line[4],$line[5]\n";
      }
    }  
        
    return 0;
};

#######################
# SHow MOVEAble ########################################################################################################
#######################
&msg( '0110D', 'SHow MOVEAble' );
my %moveable;
$Commands{&commandRegexp( "show", "moveable", 2, 5 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow MOVEAble Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my $stg = $3;
    my $pct = $4;
    
    $stg = '' if ( ! defined $stg );
    $pct = 30 if ( ! defined $pct || $pct eq '' );
   
    my @query = &runTabdelDsmadmc( "select stgpool_name, volume_name, pct_utilized, status from volumes where stgpool_name in (select stgpool_name from stgpools where devclass in (select DEVCLASS_NAME from DEVCLASSES where WORM='NO' and DEVCLASS_NAME!='DISK')) and access='READWRITE' and stgpool_name like upper('$stg%') and pct_utilized <= $pct and ((status='FILLING' and 1 < (select count(*) from volumes where access='READWRITE' and status='FILLING' and stgpool_name like upper('$stg%'))) or (status='FULL' and 0 < (select count(*) from volumes where access='READWRITE' and status='FILLING' and stgpool_name like upper('$stg%')))) order by pct_utilized desc" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'MOVEABLE';

    my @printable;
    # add the deltas
    for ( @query ) {
        my @line = split( /\t/ );
    
        # for PctUtilMigr
        splice( @line, 2, 0, '' );
        &different( \%moveable, \@line, 1, 2, 3 );
    
        $line[1] = "[".$line[1]."]";
    
        push( @printable, join( "\t", @line ) )
    }
   
    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tStgpoolName\tVolumeName{RIGHT}\td\tPct\tStatus", &addLineNumbers( @printable ) );
    
    return 0;
};

#############
# different
#############
sub different ($$$$$) {
  my $r_hash    = $_[0];
  my $r_array   = $_[1];
  my $index_poz = $_[2];
  my $diff_poz  = $_[3];
  my $value_poz = $_[4];

 if ( defined $r_hash->{@$r_array[$index_poz]} ) {
    if ( $r_hash->{@$r_array[$index_poz]} > @$r_array[$value_poz] ) {
      @$r_array[$diff_poz] = '-';
    }
    elsif ( $r_hash->{@$r_array[$index_poz]} < @$r_array[$value_poz] ) {
      @$r_array[$diff_poz] = '+';
    }
    elsif ( $r_hash->{@$r_array[$index_poz]} = @$r_array[$value_poz] ) {
      @$r_array[$diff_poz] = '=';
    }
    else {
      @$r_array[$diff_poz] = '';
    }
  }

  $r_hash->{@$r_array[$index_poz]} = @$r_array[$value_poz];

};

1;
