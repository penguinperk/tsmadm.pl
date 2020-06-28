#!/usr/bin/perl

use strict;
use warnings;
use Pod::Usage;
use POSIX;

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

&msg( '0110D', 'new Dedup commands' );

#######################
# SHow STAtus ########################################################################################################
#######################
&msg( '0110D', 'SHow dedup' );
$Commands{&commandRegexp( "show", "Dedup", 2, 3 )} = sub {

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
		my $Empty = 0;
    
    my $DBMAX = 90;
    my $DBHITMIN = 99;
    
    my $LOGMAX = 60;
    #
    my $FULLDB = 2;
    
    my $DBLASTHOUR = 2;
    my $DBLASTFULLHOUR = 24;
    
    my $DBerrorcollector = 0;
   # my $NumDedupProsses = "select count(process) from  processes where process='Identify Duplicates'"

    if ( $TSMSeverStatus{VERSION} <= 5 ) {

        # DB v5
        push ( @printable, "Dedup is not supported below TSM Version 6");

    }
    else { # TSM V6
    	
#    	   # UNAVAILABLE volumes
#    @query = &runTabdelDsmadmc( "select count(*) from volumes where access like '%UNAVA%'" );
#    return 0 if ( $LastErrorcode );
#    
#    my $UnavaStatus = "  Ok";
#    $query[0] = 0 if ( ! defined $query[0] );
#    if ( $query[0] > 0 ) {
#        $UnavaStatus = &colorString( "Failed!", "BOLD RED");
#    }
#    push ( @printable, " Unavailable Vol(s)\t$AllVolumes/$query[0]\t$UnavaStatus" );
 # READ-ONLY volumes
#    @query = &runTabdelDsmadmc( "select count(*) from volumes" );
#    my $AllVolumes = ( defined $query[0] ) ? $query[0] : '0';
#    
#    @query = &runTabdelDsmadmc( "select count(*) from volumes where access like '%READO%'" );
#    return 0 if ( $LastErrorcode );
#    
#    my $ReadOnlyStatus = "  Ok";
#    $query[0] = 0 if (! defined $query[0] );
#    if ( $query[0] > 0 ) {
#        $ReadOnlyStatus = &colorString( "Failed!", "BOLD RED");
#    }
#    push ( @printable, " ReadOnly Vol(s)\t$AllVolumes/$query[0]\t$ReadOnlyStatus" );
#        
        # DB v6 
        
        # my ( $IdentifyCount, $DedupSum ) = ( split( /\t/, $query[0] ) );
        
        ####################
				#HEADER
				####################

        push ( @printable, "Identify Duplicates");
        
        ####################
				#Total Volumes Inspected
				####################
        @query = &runTabdelDsmadmc( "select Count(distinct(Volume_name)) from summary where start_time>=current_timestamp - 24 hours and activity='IDENTIFY'" );       
        my $VolumesInsp = ( defined $query[0] ) ? $query[0] : '0';
        return 0 if ( $#query < 0 || $LastErrorcode );
        push ( @printable, " Total Volumes Inspected\t$VolumesInsp" );
        
        ####################
				#Total Capacity inspected
				####################
        @query = &runTabdelDsmadmc( "select bytes from summary where start_time>=current_timestamp - 24 hours and activity='IDENTIFY'" );    
        my $DedupSum = ( defined $query[0] ) ? $query[0] : '0'; 
        
        $DedupSum = &byteFormatter ( $DedupSum, 'MB' );
        push ( @printable, " Total Capacity Inspected\t$DedupSum\t");       
        
        ####################
				#Exaimed & Affected Chunks
				####################
        @query = &runTabdelDsmadmc( "select sum(EXAMINED),sum(AFFECTED) from summary where start_time>=current_timestamp - 24 hours and activity='IDENTIFY'" );
        return 0 if ( $#query < 0 || $LastErrorcode );
        #my ( $EXAMINED, $AFFECTED ) = ( split( /"\t"/, $query[0] ) );
				#$EXAMINED = ( defined $query[0] ) ? $query[0] : '0';  
				#$AFFECTED = ( defined $query[1] ) ? $query[1] : '1'; 
       
        
        ##Look at using this 
        #push ( @printable, " Last Full DBBackup\t$dbLastFullBackupHour\t$DBFullBackupStatus") if ( defined $dbLastFullBackupHour );
 				foreach ( @query ) {
					my @line = split(/\t/);
				        
				        	push ( @printable, " Ojbects Examine\\Affected \t$line[0]\\$line[1]\t" );

				}
			
##			  $DedupSum = &byteFormatter ( $DedupSum, 'MB' );
##         push ( @printable, " Total Capacity Inspected\t$DedupSum\t");
##      	
				
				push ( @printable, "\n");
				
				####################
				#
				####################
				@query = &runTabdelDsmadmc( "select stgpool_name, IDENTIFYPROCESS,MAXSCRATCH, NUMSCRATCHUSED,  MAXSCRATCH - NUMSCRATCHUSED as available_scratch, SPACE_SAVED_MB   from stgpools where DEDUPLICATE='YES'" );    
        my $Stuff = ( defined $query[0] ) ? $query[0] : '0'; 
        
        my @currentProcesses = &runTabdelDsmadmc( "select count(*) from processes where process='Identify Duplicates'" );
        
        my ( $StgPoolName, $IdentifyProcesses, $MaxScratch, $NumScratchUsed, $AvailableScratch, $SpaceSavedMB ) = ( split( /\t/, $query[0] ) );
        
        $SpaceSavedMB = &byteFormatter ( $SpaceSavedMB, 'MB' );
          
          
        push ( @printable, "Storage Pool\t$StgPoolName") if ( defined $StgPoolName );
        push ( @printable, " Identify Process\t$IdentifyProcesses\\@currentProcesses") if ( defined $IdentifyProcesses );
        push ( @printable, " Scratch (Max\\Used)\t$MaxScratch\\$NumScratchUsed") if ( defined $MaxScratch );
        push ( @printable, " Available Scratch\t$AvailableScratch") if ( defined $AvailableScratch );
        push ( @printable, " Capacity Saved\t$SpaceSavedMB") if ( defined $SpaceSavedMB );
        ##Calculate the dedup ratio
        ###push ( @printable, " DedupRatio\t$DedupRatio") if ( defined $DedupRatio );
        
#        
#         
#         
#				## Actual Duration of identify processs 
#        @query = &runTabdelDsmadmc( "select  timestampdiff(8,  max(end_time) - min(start_time)) as Duration_Min from summary where start_time>=current_timestamp - 24 hours and activity='IDENTIFY'" );
#        my @NumDedupProsses = &runTabdelDsmadmc( "select count(process) from  processes where process='Identify Duplicates'" ); 
#        return 0 if ( $#query < 0 || $LastErrorcode );
#        
#        my @ActDuratation;
#        
#        if ( $NumDedupProsses[0] > 0 ) {
#        	#@ActDuratation;
#        }
#        else{
#        	@ActDuratation[0] = $query[0] \ $NumDedupProsses[0];
#        }
#        
#        push ( @printable, " Duration Identifies \t$ActDuratation[0]\t" );
         
        
        

 
         
         push ( @printable, "\t\t" );
        
        #########################################################################################################
        #########################################################################################################
        #########################################################################################################
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
#        push ( @printable, "LOG\t\t");
#        my $LOGerrorcollector = 0;
#        @query = &runTabdelDsmadmc( "select FREE_SPACE_MB, ACTIVE_LOG_DIR, ARCH_LOG_DIR, MIRROR_LOG_DIR, AFAILOVER_LOG_DIR from log" );
#        return 0 if ( $#query < 0 || $LastErrorcode );
#        
#        my ( $logFreeSpace, $logActLogDir, $logArchLogDir, $logMirrorDir, $logArchFailLog ) = ( split( /\t/, $query[0] ) );
#        
#        $logFreeSpace = &byteFormatter ( $logFreeSpace, 'MB' );
#        push ( @printable, " FreeSpace\t$logFreeSpace\t");
#        push ( @printable, " ActiveLog\t$logActLogDir\t");
#        push ( @printable, " ArchiveLog\t$logArchLogDir\t");
#        push ( @printable, " ActiveMirror\t$logMirrorDir\t");
#        push ( @printable, " ArchiveLogFail\t$logArchFailLog\t");
#        
#        if ( $LOGerrorcollector > 0 ) {
#            push ( @printable, " Status\t=> \t".&colorString( "Failed!", "BOLD RED"));
#        }
#        else {
#            push ( @printable, " Status\t=>\t [OK]");
#        }
#        
#    }
#    push ( @printable, "\t\t" );
#
#    push ( @printable, "VOLs\t\t");
#    # READ-ONLY volumes
#    @query = &runTabdelDsmadmc( "select count(*) from volumes" );
#    my $AllVolumes = ( defined $query[0] ) ? $query[0] : '0';
#    
#    @query = &runTabdelDsmadmc( "select count(*) from volumes where access like '%READO%'" );
#    return 0 if ( $LastErrorcode );
#    
#    my $ReadOnlyStatus = "  Ok";
#    $query[0] = 0 if (! defined $query[0] );
#    if ( $query[0] > 0 ) {
#        $ReadOnlyStatus = &colorString( "Failed!", "BOLD RED");
#    }
#    push ( @printable, " ReadOnly Vol(s)\t$AllVolumes/$query[0]\t$ReadOnlyStatus" );
#    
#    # UNAVAILABLE volumes
#    @query = &runTabdelDsmadmc( "select count(*) from volumes where access like '%UNAVA%'" );
#    return 0 if ( $LastErrorcode );
#    
#    my $UnavaStatus = "  Ok";
#    $query[0] = 0 if ( ! defined $query[0] );
#    if ( $query[0] > 0 ) {
#        $UnavaStatus = &colorString( "Failed!", "BOLD RED");
#    }
#    push ( @printable, " Unavailable Vol(s)\t$AllVolumes/$query[0]\t$UnavaStatus" );
#    
#    # SUSPICIOUS volumes
#    @query = &runTabdelDsmadmc( "select count(*) from volumes where WRITE_ERRORS>0 or READ_ERRORS>0" );
#    return 0 if ( $LastErrorcode );
#    
#    my $SusStatus = "  Ok";
#    $query[0] = 0 if ( ! defined $query[0] );
#    if ( $query[0] > 0 ) {
#        $SusStatus = &colorString( "Warning!", "BOLD YELLOW" );
#    }
#    push ( @printable, " Suspicious Vol(s)\t$AllVolumes/$query[0]\t$SusStatus" );
#  
#    push ( @printable, "\t\t" );
#  
#    push ( @printable, "HW\t\t");  
#    # DRIVES
#    @query = &runTabdelDsmadmc( "select count(*) from drives" );
#    return 0 if ( $LastErrorcode );
#    
#    my $OnlineDrives = ( defined $query[0] ) ? $query[0] : '0';
#    
#    @query = &runTabdelDsmadmc( "select count(*) from drives where online='NO'" );
#    return 0 if ( $LastErrorcode );
#    
#    my $DriveStatus = "  Ok";
#    $query[0] = 0 if ( ! defined $query[0] );
#    if ( $query[0] > 0 ) {
#      $DriveStatus = &colorString( "Failed!", "BOLD RED")." /* Use 'show drives' command! */";
#    }
#    push ( @printable, " Offline Drive(s)\t$OnlineDrives/$query[0]\t$DriveStatus");
#    # PATHS
#    @query = &runTabdelDsmadmc( "select count(*) from paths");
#    return 0 if ( $LastErrorcode );
#    
#    my $OnlinePaths = ( defined $query[0] ) ? $query[0] : '0';
#    @query = &runTabdelDsmadmc( "select count(*) from paths where online='NO'");
#    return 0 if ( $LastErrorcode );
#    
#    my $PathStatus = "  Ok";
#    $query[0] = 0 if ( ! defined $query[0] );
#    if ( $query[0] > 0 ) {
#      $PathStatus = &colorString( "Failed!", "BOLD RED")." /* Use 'show path' command! */";
#    }
#    push ( @printable, " Offline Path(s)\t$OnlinePaths/$query[0]\t$PathStatus");
#
#    push ( @printable, "\t\t" );
#
#    # EVENTS
#    push ( @printable, "<24 H Client Event Summary\t\t");
#    @query = &runTabdelDsmadmc( "select result, count(1) from events where status='Completed' and SCHEDULED_START>'2012-01-01 00:00:00' and (SCHEDULED_START>=current_timestamp-24 hour) and DOMAIN_NAME is not null and NODE_NAME is not null group by result" );
#    
#    foreach ( @query ) {
#        my @line = split(/\t/);
#        
#        if ( $line[0] eq 0 ) {
#            push ( @printable, " Completed and result \[$line[0]\]\t$line[1]\t  Ok" );
#        }
#        elsif ( $line[0] eq 4 || $line[0] eq 8 ) {
#            push ( @printable, " Completed and result \[$line[0]\]\t$line[1]\t".&colorString( "Warning!", "BOLD YELLOW" ) );
#        }
#        else {
#            push ( @printable, " Completed and result \[$line[0]\]\t$line[1]\t".&colorString( "Failed!", "BOLD RED") );
#        }
#        
#    }
#
#    @query = &runTabdelDsmadmc( "select count(1) from events where status='Missed' and SCHEDULED_START>'2012-01-01 00:00:00' and (SCHEDULED_START>=current_timestamp-24 hour) and DOMAIN_NAME is not null and NODE_NAME is not null" );
#    my $MissedEvents = ( defined $query[0] ) ? $query[0] : '0';
#   
#    if ( $MissedEvents eq 0 ) {
#        push ( @printable, " Missed\t$MissedEvents\t  Ok" );
#    }
#    else {
#        push ( @printable, " Missed\t$MissedEvents\t".&colorString( "Failed!", "BOLD RED") );
#    }
#    
#    @query = &runTabdelDsmadmc( "select count(1) from events where status='Failed' and SCHEDULED_START>'2012-01-01 00:00:00' and (SCHEDULED_START>=current_timestamp-24 hour) and DOMAIN_NAME is not null and NODE_NAME is not null" );
#    my $FailedEvents = ( defined $query[0] ) ? $query[0] : '0';
#   
#    if ( $FailedEvents eq 0 ) {
#        push ( @printable, " Failed\t$FailedEvents\t  Ok" );
#    }
#    else {
#        push ( @printable, " Failed\t$FailedEvents\t".&colorString( "Failed!", "BOLD RED") );
#    }
#    push ( @printable, "\t\t" );
#    
#    push ( @printable, "<24 H Admin Event Summary\t\t");
#    @query = &runTabdelDsmadmc( "select result, count(1) from events where status='Completed' and SCHEDULED_START>'2012-01-01 00:00:00' and (SCHEDULED_START>=current_timestamp-24 hour) and DOMAIN_NAME is null and NODE_NAME is null group by result" );
#    
#    foreach ( @query ) {
#        my @line = split( /\t/ );
#        
#        if ( $line[0] eq 0 ) {
#            push ( @printable, " Completed and result \[$line[0]\]\t$line[1]\t  Ok" );
#        }
#        elsif ( $line[0] eq 4 || $line[0] eq 8 ) {
#            push ( @printable, " Completed and result \[$line[0]\]\t$line[1]\t".&colorString( "Warning!", "BOLD YELLOW" ) );
#        }
#        else {
#            push ( @printable, " Completed and result \[$line[0]\]\t$line[1]\t".&colorString( "Failed!", "BOLD RED" ) );
#        }
#        
#    }
#
#    @query = &runTabdelDsmadmc( "select count(1) from events where status='Missed' and SCHEDULED_START>'2012-01-01 00:00:00' and (SCHEDULED_START>=current_timestamp-24 hour) and DOMAIN_NAME is null and NODE_NAME is null" );
#    $MissedEvents = ( defined $query[0] ) ? $query[0] : '0';
#   
#    if ( $MissedEvents eq 0 ) {
#        push ( @printable, " Missed\t$MissedEvents\t  Ok" );
#    }
#    else {
#        push ( @printable, " Missed\t$MissedEvents\t".&colorString( "Failed!", "BOLD RED" ) );
#    }
#    
#    @query = &runTabdelDsmadmc( "select count(1) from events where status='Failed' and SCHEDULED_START>'2012-01-01 00:00:00' and (SCHEDULED_START>=current_timestamp-24 hour) and DOMAIN_NAME is null and NODE_NAME is null" );
#    $FailedEvents = ( defined $query[0] ) ? $query[0] : '0';
#   
#    if ( $FailedEvents eq 0 ) {
#        push ( @printable, " Failed\t$FailedEvents\t  Ok" );
#    }
#    else {
#        push ( @printable, " Failed\t$FailedEvents\t".&colorString( "Failed!", "BOLD RED" ) );
#    }    
#    
#    push ( @printable, "\t\t" );
#
#    # ACTLOG
#    push ( @printable, "<24 H Activity Summary\t\t");
#    @query = &runTabdelDsmadmc( "select severity,count(1) from actlog where (DATE_TIME>=current_timestamp-24 hour) and severity in ('E','W') and MSGNO not in (2034) group by severity" );
#    
#    foreach ( @query ) {
#        my @line = split( /\t/ );
#        
#        if ( $line[0] eq 'W' ) {
#            push ( @printable, " Warnings\t$line[1]\t".&colorString( "Warning!", "BOLD YELLOW" ) );
#        }
#        elsif ( $line[0] eq 'E' ) {
#            push ( @printable, " Errors\t$line[1]\t".&colorString( "Failed!", "BOLD RED" ) );
#        }
#        
    }    
    &setSimpleTXTOutput();
    &universalTextPrinter( "Item\tValue{RIGHT}\tResult", @printable );
    
    return 0;
};
&defineAlias( 'dedup', 'show dedup' );
