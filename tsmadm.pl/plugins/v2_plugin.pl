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

    my @query = &runTabdelDsmadmc( "select node_name, sum(logical_mb), sum(num_files) from occupancy where node_name like upper('$3%') group by node_name order by 2 desc" );
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

    my @query = &runTabdelDsmadmc( "select date(DATE_TIME),time(DATE_TIME),TYPE,BACKUP_SERIES,BACKUP_OPERATION,VOLUME_SEQ,DEVCLASS,'['||VOLUME_NAME||']' from volhistory where type='BACKUPFULL' or type='BACKUPINCR' order by BACKUP_SERIES" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'BACKUP';
   
    &setSimpleTXTOutput();
    &universalTextPrinter( "Date\tTime\tType\tSerie{RIGHT}\t#{RIGHT}\tSeq{RIGHT}\tDeviceClass\tVolume{RIGHT}", @query );

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
        @query = &runTabdelDsmadmc( "select FREE_SPACE_MB, BUFF_HIT_RATIO, PKG_HIT_RATIO, LAST_REORG, hour(current_timestamp-LAST_BACKUP_DATE) from db" );
        return 0 if ( $#query < 0 || $LastErrorcode );
        
        my ( $dbFreeSpace, $dbCacheHitPct, $dbPkgHitPct, $dbLastBackupDay ) = ( split( /\t/, $query[0] ) );
        
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
    push ( @printable, "ReadOnly Vol(s)\t$AllVolumes/$query[0]\t$ReadOnlyStatus" );
    
    # UNAVAILABLE volumes
    @query = &runTabdelDsmadmc( "select count(*) from volumes where access like '%UNAVA%'" );
    return 0 if ( $LastErrorcode );
    
    my $UnavaStatus = "  Ok";
    $query[0] = 0 if ( ! defined $query[0] );
    if ( $query[0] > 0 ) {
        $UnavaStatus = &colorString( "Failed!", "BOLD RED");
    }
    push ( @printable, "Unavailable Vol(s)\t$AllVolumes/$query[0]\t$UnavaStatus" );
    
    # SUSPICIOUS volumes
    @query = &runTabdelDsmadmc( "select count(*) from volumes where WRITE_ERRORS>0 or READ_ERRORS>0" );
    return 0 if ( $LastErrorcode );
    
    my $SusStatus = "  Ok";
    $query[0] = 0 if ( ! defined $query[0] );
    if ( $query[0] > 0 ) {
        $SusStatus = &colorString( "Warning!", "BOLD YELLOW" );
    }
    push ( @printable, "Suspicious Vol(s)\t$AllVolumes/$query[0]\t$SusStatus" );
  
    push ( @printable, "\t\t" );
  
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
    push ( @printable, "Offline Drive(s)\t$OnlineDrives/$query[0]\t$DriveStatus");
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
    push ( @printable, "Offline Path(s)\t$OnlinePaths/$query[0]\t$PathStatus");

    push ( @printable, "\t\t" );

    # EVENTS
    push ( @printable, "Event Summary\t\t");
    
    @query = &runTabdelDsmadmc( "select result, count(1) from events where status='Completed' and (SCHEDULED_START >= current_timestamp - 1 day) group by result" );
    return 0 if ( $LastErrorcode );

    foreach ( @query ) {
        my @line = split(/\t/);
        
        if ( $line[0] eq 0 ) {
            push ( @printable, " Completed and result \[$line[0]\]\t$line[1]\t  Ok" );
        }
        elsif ( $line[0] eq 4 ) {
            push ( @printable, " Completed and result \[$line[0]\]\t$line[1]\t".&colorString( "Warning!", "BOLD YELLOW" ) );
        }
        else {
            push ( @printable, " Completed and result \[$line[0]\]\t$line[1]\t"..&colorString( "Failed!", "BOLD RED") );
        }
        
    }

    @query = &runTabdelDsmadmc( "select count(1) from events where status='Missed' and (SCHEDULED_START >= current_timestamp - 1 day)" );
    my $MissedEvents = ( defined $query[0] ) ? $query[0] : '0';
   
    if ( $MissedEvents eq 0 ) {
        push ( @printable, " Missed\t$MissedEvents\t  Ok" );
    }
    else {
        push ( @printable, " Missed\t$MissedEvents\t".&colorString( "Failed!", "BOLD RED") );
    }
    
    &setSimpleTXTOutput();
    &universalTextPrinter( "Item\tValue{RIGHT}\tResult", @printable );
    
    return 0;
};

1;
