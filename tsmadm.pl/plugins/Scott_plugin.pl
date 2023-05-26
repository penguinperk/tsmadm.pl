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


&msg( '0110D', 'Scotts commands' );

my @temp;

#######################
# SHow TSM for Virtual Environment ##################################################################################################
#######################

&msg( '0110D', 'SHow veocc' );
$Commands{&commandRegexp( "show", "veocc" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow VEOCC Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }



  my @query = &runTabdelDsmadmc("select FILESPACE_NAME, stgpool_name, REPORTING_MB from occupancy where node_name like '%_DATACENTER'");
  return if ( $#query < 0 );

  &setSimpleTXTOutput();

  &universalTextPrinter( "#{RIGHT}\tVE_Node\tStgPool\tReported_OCC", &addLineNumbers( @query ) );

  return 0;


};

###############
# SHow enhaced weekly ##########################################################################################################
###############
&msg( '0110D', 'SHow eweekly' );
$Commands{&commandRegexp( "show", "eweekly" )} = sub {

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

    my @query = &runTabdelDsmadmc('q event * * begind=-7 endd=today endt=now f=d ex=yes'.$3.' '.$4.' '.$5);
	
	#my @MY = uniq @query;
	
    return if ( $#query < 0 || $LastErrorcode );

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
        

        elsif ( $line[6] =~ m/missed/i ) {
            $line[7] = &colorString( $line[7], "BOLD YELLOW" );
        }
        elsif ( $line[6] =~ m/failed/i ) {
            $line[6] = &colorString( $line[6], "BOLD RED" );
            $line[7] = &colorString( $line[7], "BOLD RED" );
        }
        elsif ( $line[6] =~ m/severed/i ) {
            $line[6] = &colorString( $line[6], "BOLD RED" );
            $line[7] = &colorString( $line[7], "BOLD RED" );
        }
        elsif ( $line[6] =~ m/started/i ) {
            $line[6] = &colorString( $line[6], "BOLD GREEN" );
        }
        elsif ( $line[6] =~ m/pending/i ) {
            $line[6] = &colorString( $line[6], "GREEN" );
        }

        push ( @printable, join( "\t", @line ) );

        &pbarUpdate( $i++ );

    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tDomain\tScheduleName\tNodeName\tScheduledStart\tActStart{RIGHT}\tCompleted{RIGHT}\tStatus\tRC{RIGHT}", &addLineNumbers( @printable ) );

    return 0;

};
&defineAlias( 'sh exc', 'show events exc=yes' );

#######################
# SHow DefineASSOciations ##################################################################################################
#######################

&msg( '0110D', 'SHow DefASSociation' );
$Commands{&commandRegexp( "show", "defassociation" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow DefASSociation Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

  $LastCommandType = 'ASSOC';

  my @query = &runTabdelDsmadmc("select 'Define Association',DOMAIN_NAME,SCHEDULE_NAME,NODE_NAME from associations where NODE_NAME like upper('%".$3."%')");
##my @query = &runTabdelDsmadmc("select DOMAIN_NAME,SCHEDULE_NAME,NODE_NAME from associations where NODE_NAME like upper('%".$3."%')");
  return if ( $#query < 0 );

  &setSimpleTXTOutput();

  &universalTextPrinter( "#{RIGHT}\tCommand1\tDomain\tSchedule\tNode Name", &addLineNumbers( @query ) );
##&universalTextPrinter( "#{RIGHT}\tDomain\tSchedule\tNode Name", &addLineNumbers( @query ) );
  return 0;

};



#######################
# SHow drVolume ##################################################################################################
#######################

&msg( '0110D', 'SHow drvolume' );
$Commands{&commandRegexp( "show", "drvolume" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow DR Media Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

  $LastCommandType = 'ASSOC';

  my @query = &runTabdelDsmadmc("select location, count(volume_name) from drmedia where location<>'NULL'  group by location");
  return if ( $#query < 0 );

  &setSimpleTXTOutput();

  &universalTextPrinter( "DR Location\t# of Volumes", @query );

  return 0;

};

#######################
# SHow Event Archive  ##################################################################################################
#######################

&msg( '0110D', 'SHow event_archive' );
$Commands{&commandRegexp( "show", "event_archive" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow retention Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

  my @query = &runTabdelDsmadmc("select schedule_name, actual_start, node_name, completed, result, status,  timestampdiff(4, char(completed - actual_start)) from events where schedule_name like 'ARCHIVE%'");
  return if ( $#query < 0 );

  &setSimpleTXTOutput();

  &universalTextPrinter( "#{RIGHT}\tSchedule Name\tActual Start\tNode Name\tCompleted\tResult\tStatus\tArchive Duration Minutes", &addLineNumbers( @query ) );

  return 0;

};

#######################
# SHow Backup Retention ##################################################################################################
#######################

&msg( '0110D', 'SHow backup_retention' );
$Commands{&commandRegexp( "show", "backup_retention" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow retention Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

  my @query = &runTabdelDsmadmc("select DOMAIN_NAME, SET_NAME,CLASS_NAME, VEREXISTS,VERDELETED,RETEXTRA,RETONLY, DESTINATION from bu_copygroups");
  return if ( $#query < 0 );

  &setSimpleTXTOutput();

  &universalTextPrinter( "#{RIGHT}\tDomain\tPolicySet\tMgmtClass\tActiveVersion\tDeletedVersion\tActiveDays\tDeletedDays\tDestination", &addLineNumbers( @query ) );

  return 0;

};

#######################
# SHow Reorg ##################################################################################################
#######################

&msg( '0110D', 'SHow reorgOpt' );
$Commands{&commandRegexp( "show", "reorgopt" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow reorgOpt Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

  my @query = &runTabdelDsmadmc("select * from options where option_name like '%org%' or option_name like '%ORG%'");
  return if ( $#query < 0 );

  &setSimpleTXTOutput();

  &universalTextPrinter( "#{RIGHT}\tOptionName\tSetting", &addLineNumbers( @query ) );

  return 0;

};

#######################
# SHow Archive Retention ##################################################################################################
#######################

&msg( '0110D', 'SHow archive_retention' );
$Commands{&commandRegexp( "show", "archive_retention" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow archive_retention Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

#  $LastCommandType = 'ASSOC';

  my @query = &runTabdelDsmadmc("select DOMAIN_NAME, SET_NAME,CLASS_NAME, RETver, RETMIN, DESTINATION from AR_COPYGROUPS");
  return if ( $#query < 0 );

  &setSimpleTXTOutput();

  &universalTextPrinter( "#{RIGHT}\tDomain\tPolicySet\tMgmtClass\tRetainVersion\tRetainMin\tDestination", &addLineNumbers( @query ) );

  return 0;

};

#######################
# SHow device Class ##################################################################################################
#######################

&msg( '0110D', 'SHow devclass' );
$Commands{&commandRegexp( "show", "devclass" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow devclass Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }


  my @query = &runTabdelDsmadmc("select DEVCLASS_NAME, ACCESS_STRATEGY, STGPOOL_COUNT, DEVTYPE, FORMAT, CAPACITY, MOUNTLIMIT, DIRECTORY from devclasses");
  return if ( $#query < 0 );

  &setSimpleTXTOutput();

  &universalTextPrinter( "#{RIGHT}\tDevice Name\tDevice Access\tStgpool Count\tDevice Type\tFormat\tCapacity(MB)\tMountLimit\tDirectory", &addLineNumbers( @query ) );

  return 0;

};

#################
# Show history #
#################
&msg( '0110D', 'history' );
$Commands{qr/^(history)\s*(\S*)/i} = sub {
  @temp = @History;
  my $j = 0;
  foreach (@temp) {$temp[$j] =~ s/\t/    /g; $j++;} ## a kiiro miatt a TAB-okat kicserelem szóközkre
  my @temp = addLineNumbers(@temp);
  &universalTextPrinter(" #\tCommand",@temp);
  return 0;
};
#####################
# Show Activity Log #
#####################
&msg( '0110D', 'SHow actlog' );
$Commands{qr/^(show)\s*(actlog)(\S*)/i} = sub {
  my @content = &runTabdelDsmadmc("q actlog begint=-00:01");
  &universalTextPrinter("Date/Time\tMessage",@content);
  return 0;
};

#####################
# Show BackupTotal #
#####################
&msg( '0110D', 'SHow Backuptotal' );
$Commands{qr/^(show|^sho|^sh)\s*(backuptotal)(\S*)/i} = sub {
  
  my @content = &runTabdelDsmadmc("select cast(float(sum(bytes))/1024/1024/1024 as decimal(24,2)) from summary where start_time>=current_timestamp - 24 hours and (activity='BACKUP' or substr(activity,1,3)='NAS')");
  &universalTextPrinter("Total GB Backup in the last 24 hours",@content);
  
  
  my @content2 = &runTabdelDsmadmc("select entity, cast(float(sum(bytes))/1024/1024/1024 as decimal(24,2)) from summary where start_time>=current_timestamp - 24 hours and (activity='BACKUP' or substr(activity,1,3)='NAS') group by entity order by 2");
  &universalTextPrinter("Node\tTotal GB Backup in the last 24 hours",@content2);
  return 0;
};
&defineAlias( 'sh bt',    'SHow Backuptotal' );

#####################
# Show Nodebackup #
#####################
&msg( '0110D', 'SHow nodebackup' );
$Commands{qr/^(show|^sho|^sh)\s*(nodebackup|nb)(\S*)/i} = sub {
  my @content = &runTabdelDsmadmc("select entity, cast(float(sum(bytes))/1024/1024/1024 as decimal(24,2)) from summary where start_time>=current_timestamp - 24 hours and (activity='BACKUP' or substr(activity,1,3)='NAS') group by entity order by 2");
  &universalTextPrinter("Node\tTotal GB Backup in the last 24 hours",@content);
  return 0;
};
&defineAlias( 'sh nb',    'show nodebackup' );


#####################
# Show NodeDelta #
#####################
&msg( '0110D', 'SHow nodedelta' );
$Commands{qr/^(show|^sho|^sh)\s*(nodedelta|nd)(\S*)/i} = sub {
	
	&runDsmadmc("audit license");
	sleep(10);
	
	my @content1 = &runTabdelDsmadmc("select sum(backup_copy_mb-backup_mb)/1024 from auditocc");
  &universalTextPrinter("Total Capacity NOT protected (GB)",@content1);
  

  my @content2 = &runTabdelDsmadmc("select node_name, (backup_copy_mb-backup_mb)/1024 from auditocc order by 2");
  &universalTextPrinter("Node\tCapacity not protected (GB)",@content2);
  

  
  return 0; 
};

#####################
# Show avgTapeCap #
#####################
&msg( '0110D', 'SHow avgTapeCap' );
$Commands{qr/^(show|^sho|^sh)\s*(avgTapeCap)(\S*)/i} = sub {
	

	
	my @content = &runTabdelDsmadmc("select stgpool_name, avg((EST_CAPACITY_MB*PCT_UTILIZED)/100) from volumes where status='FULL' group by stgpool_name");
 
 my @printable;
  
  foreach ( @content ) {
      my @line = split ( /\t/ );
      $line[1] = &byteFormatter ( $line[1], 'MB' );

      push( @printable, join( "\t", $line[0], $line[1] )); 
 
 
 }
    

 
 
  &universalTextPrinter("Average Tape Capacity", @printable);
  

  
  return 0; 
};


#####################
# Show VOlumeStatus #
#####################
&msg( '0110D', 'SHow VolumeStatus' );
$Commands{qr/^(show|^sho|^sh)\s*(volumestatus)(\S*)/i} = sub {
	
	my @content1 = &runTabdelDsmadmc("select access, count(access) from volumes where access<>'READWRITE' and access<>'OFFSITE' group by access");

  my @printable;
  
  foreach ( @content1 ) {
      my @line = split ( /\t/ );
      
        if ( $line[1] > 0 ) {
         $line[0] = &colorString( "$line[0]", "BOLD RED" );
        }
       
    
      push( @printable, join( "\t", $line[0], $line[1] )); 
    }
       
    if ( @printable ) {
    	#print "array not empty\n";
    	&universalTextPrinter("Number of volumes not accessable",@printable);
    	
    	my @content2 = &runTabdelDsmadmc("select access, volume_name  from volumes where access<>'READWRITE' and access<>'OFFSITE'");
  		&universalTextPrinter("Access\tVolume Name",@content2);
    }
    else {
    	#print "Array empty\n";
    	 &universalTextPrinter("Number of volumes not accessable",@printable[0] = "***All of the volumes are in good shape***");
    }

  return 0; 
};
&defineAlias( 'sh vs',    'show Volumestatus' );

#####################
# Show DBSpace #
#####################
&msg( '0110D', 'SHow DBSpace' );
$Commands{qr/^(show|^sho|^sh)\s*(dbspace)(\S*)/i} = sub {
  my @content = &runTabdelDsmadmc("select LOCATION, TOTAL_FS_SIZE_MB, USED_FS_SIZE_MB, FREE_SPACE_MB, decimal((float(USED_FS_SIZE_MB) / float(TOTAL_FS_SIZE_MB) * 100), 5,2) from DBSPACE");
 
  my @printable;
  
  foreach ( @content ) {
      my @line = split ( /\t/ );
 
      $line[1] = &byteFormatter ( $line[1], 'MB' );
      $line[2] = &byteFormatter ( $line[2], 'MB' );
      $line[3] = &byteFormatter ( $line[3], 'MB' );

        if ( $line[4] >= 75 && $line[4] <= 90 ) {
          $line[4] = &colorString( "$line[4]", "BOLD YELLOW" );
        }
        elsif ( $line[4] > 91 ) {
          $line[4] = &colorString( "$line[4]", "BOLD RED" );
        }
    
      push( @printable, join( "\t", $line[0], $line[1], $line[2], $line[3],$line[4] )); 
    }
     
      
      &universalTextPrinter("LOCATION\tTOTAL FS SIZE\tUSED FS SIZE\tFREE SPACE\t% Utilized",@printable);
  return 0;
};


#####################
# Show Expiration #
#####################
&msg( '0110D', 'SHow Expp' );
$Commands{qr/^(show)\s*(Expp)(\S*)/i} = sub {
  my @content = &runTabdelDsmadmc("select Date(start_time) as Date, time(start_time) as startTime, time(end_time) as EndTime, timestampdiff(4, END_TIME - START_TIME) as Duration_Min, PROCESSES as threads, EXAMINED as Objects, EXAMINED/(timestampdiff(4, END_TIME - START_TIME)), SUCCESSFUL  from summary where start_time>=current_timestamp - 10 days  and activity='EXPIRATION' and entity is NULL order by start_time");
  #my @content = &runTabdelDsmadmc("select Date(start_time) as Date, time(start_time) as startTime, time(end_time) as EndTime, timestampdiff(4, END_TIME - START_TIME) as Duration_Min, PROCESSES as threads, EXAMINED as Objects, EXAMINED/(timestampdiff(4, END_TIME - START_TIME)), SUCCESSFUL  from summary where start_time>=current_timestamp - 10 days  and activity<>'BACKUP' and activity<>'TAPE MOUNT' and activity='EXPIRATION' and entity is NULL order by start_time");
  
      
      &universalTextPrinter("Date\tStart Time\tEnd Time\tDuration Minutes\tThreads\tObjects\tObject Per Minute\tStatus",@content);
  return 0;
};

#####################
# Show Expiration #
#####################
&msg( '0110D', 'SHow pp' );
$Commands{qr/^(show)\s*(pp)(\S*)/i} = sub {
  my @content = &runTabdelDsmadmc("select Date(start_time) as Date, time(start_time) as startTime, time(end_time) as EndTime, timestampdiff(4, END_TIME - START_TIME) as Duration_Min, PROCESSES as threads, EXAMINED as Objects, EXAMINED/(timestampdiff(4, END_TIME - START_TIME)), SUCCESSFUL  from summary where start_time>=current_timestamp - 10 days  and activity='EXPIRATION' and entity is NULL order by start_time");
  #my @content = &runTabdelDsmadmc("select Date(start_time) as Date, time(start_time) as startTime, time(end_time) as EndTime, timestampdiff(4, END_TIME - START_TIME) as Duration_Min, PROCESSES as threads, EXAMINED as Objects, EXAMINED/(timestampdiff(4, END_TIME - START_TIME)), SUCCESSFUL  from summary where start_time>=current_timestamp - 10 days  and activity<>'BACKUP' and activity<>'TAPE MOUNT' and activity='EXPIRATION' and entity is NULL order by start_time");
  
      
      &universalTextPrinter("Date\tStart Time\tEnd Time\tDuration Minutes\tThreads\tObjects\tObject Per Minute\tStatus",@content);
  return 0;
};

# Show Direcotry Space #
#####################
#####################
&msg( '0110D', 'SHow dirspace' );
$Commands{qr/^(show|^sho|^sh)\s*(dir)(\S*)/i} = sub {
  my @content = &runTabdelDsmadmc("q dirspace");
      
      &universalTextPrinter("DevClass Name\tDirecotry\tEst. Capacity\tEst. Availability",@content);
  return 0;
};

#####################
# Show Extended Log 					#
#####################
&msg( '0110D', 'SHow elog' );
$Commands{qr/^(show|^sho|^sh)\s*(elog)(\S*)/i} = sub {

my @query = ();
#my @j = ();
my @printable;	

	        @query = &runTabdelDsmadmc("select 'Active Log', active_log_dir, total_space_mb, used_space_mb, decimal((used_space_mb  / total_space_mb * 100 ),5,2) as pctUsed from log");
	  push (@query, &runTabdelDsmadmc("select  'Active Mirror', MIRROR_LOG_DIR, MIRLOG_TOL_FS_MB, MIRLOG_USED_FS_MB, decimal((MIRLOG_USED_FS_MB  / MIRLOG_TOL_FS_MB * 100 ),5,2) as pctUsed from log"));
	  push (@query, &runTabdelDsmadmc("select  'Archive Log', ARCH_LOG_DIR, ARCHLOG_TOL_FS_MB, ARCHLOG_USED_FS_MB, decimal((ARCHLOG_USED_FS_MB  / ARCHLOG_TOL_FS_MB * 100 ),5,2) as pctUsed from log"));
	  push (@query, &runTabdelDsmadmc("select  'Archive Failover', AFAILOVER_LOG_DIR, AFAILOVER_TOL_FS_MB, AFAILOVER_USED_FS_MB, decimal((AFAILOVER_USED_FS_MB  / AFAILOVER_TOL_FS_MB * 100 ),5,2) as pctUsed from log"));

foreach ( @query ) {
      my @line = split ( /\t/ );
 
      $line[2] = &byteFormatter ( $line[2], 'MB' );
      $line[3] = &byteFormatter ( $line[3], 'MB' );

        if ( $line[4] >= 75 && $line[4] <= 90 ) {
          $line[4] = &colorString( "$line[4]", "BOLD YELLOW" );
        }
        elsif ( $line[4] > 91 ) {
          $line[4] = &colorString( "$line[4]", "BOLD RED" );
        }
    
      push( @printable, join( "\t", $line[0], $line[1], $line[2], $line[3],$line[4] )); 
    }

  &universalTextPrinter("Log Type\tLog Location\tTotal Capacity (MB)\tUsed Capacity (MB)\t% Used",@printable);
  return 0;
};


####################
# SHow Reclaim     #
####################
#$number = 60
&msg( '0110D', 'SHow REClaimable' );
$Commands{(qr/^(show|^sho|^sh)\s+(reclaim|rec)\b\s*(\S*)$/i)} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ######################################
        # show # of tapes Reclaimable at 60% #
        ######################################
        print "--------\n";
        print "show # of tapes Reclaimable at 60%\n";
        print "--------\n";
        return 0;
    }

		my $number = $3;
		
    my @getReclaimableVols = &runTabdelDsmadmc
    (
			"select count(*) as ReclaimableVols,stgpool_name from volumes where devclass_name<>'DISK' and pct_reclaim>=60 group by stgpool_name"
    );
    	&setSimpleTXTOutput();
    	@getReclaimableVols = addLineNumbers(@getReclaimableVols);
    	&universalTextPrinter(
					"#{%3s}\tReclaimable Volumes (60%)[RED]\tStorge Pools",
     	@getReclaimableVols
    );
    
   	@temp = @getReclaimableVols;
    
    return 0;
};




#######################
#SHow volreclaim ##################################################################################################
#######################

&msg( '0110D', 'SHow volreclaim' );
$Commands{&commandRegexp( "show", "volreclaim" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow volreclaim Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }
  my $stg = $3;
  
  #$LastCommandType = 'ASSOC';

  my @query = &runTabdelDsmadmc("select volume_name, int(((EST_CAPACITY_MB*PCT_UTILIZED)/100))/1024,EST_CAPACITY_MB, PCT_UTILIZED, pct_reclaim from volumes where pct_reclaim>=60 and stgpool_name like upper('%".$3."%') order by 5 desc");
  return if ( $#query < 0 );

  &setSimpleTXTOutput();

  &universalTextPrinter( "#{%3s}\tVolumes Name (60%)\tActual Utilization(GB)\tEST Capacity\t%PCT Utilized\tPCT Reclaim", &addLineNumbers( @query ) );
  return 0;


};
&defineAlias( 'sh volr',    'show volreclaim' );



##########################
# Show STGpools Enhanced 
##########################
&msg( '0110D', 'SHow ESTGpools' );
$Commands{&commandRegexp( "show", "estgpools" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow Enhnaced STGpools Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

   my @query = &runTabdelDsmadmc( "select STGPOOL_NAME,DEVCLASS,COLLOCATE,EST_CAPACITY_MB,PCT_UTILIZED,PCT_MIGR,HIGHMIG,LOWMIG,RECLAIM,NEXTSTGPOOL, ((EST_CAPACITY_MB*PCT_UTILIZED)/100) from stgpools", 'select_x_from_stgpools' );
         #                                         0      1         2           3              4          5        6       7      8        9                           10
   #my @query = &runTabdelDsmadmc( "select STGPOOL_NAME,DEVCLASS,COLLOCATE,EST_CAPACITY_MB,PCT_UTILIZED,PCT_MIGR,HIGHMIG,LOWMIG,RECLAIM,NEXTSTGPOOL, ((PCT_UTILIZED/100) * EST_CAPACITY_MB) from STGPOOLS", 'select_x_from_stgpools' );
    
    return if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'GENERAL';

    my @printable;

    foreach ( @query ) {
      my @line = split ( /\t/ );
      $line[3] = &byteFormatter ( $line[3], 'MB' );
      $line[5] = " " if ( ! defined ( $line[5] ) );
      $line[6] = " " if ( ! defined ( $line[6] ) );
      $line[7] = " " if ( ! defined ( $line[7] ) );
      $line[8] = " " if ( ! defined ( $line[8] ) );
      $line[9] = " " if ( ! defined ( $line[9] ) );
      $line[10] = &byteFormatter ( $line[10], 'MB' );
      
       if ( $line[1] eq 'DISK' ) {

        if ( $line[5] >= 40 && $line[5] <= 80 ) {
          $line[5] = &colorString( "$line[5]", "BOLD YELLOW" );
        }
        elsif ( $line[5] > 80 ) {
          $line[5] = &colorString( "$line[5]", "BOLD RED" );
        }
        
      }
      else {
        
        if ( $line[4] >= 80 && $line[4] <= 90 ) {
          $line[4] = &colorString( "$line[4]", "BOLD YELLOW" );
        }
        elsif ( $line[4] > 90 ) {
          $line[4] = &colorString( "$line[4]", "BOLD RED" );
        }
        
      }
      
      
      #push ( @printable, join( "\t", $line[0], $line[1], $line[2], $line[3], $line[4], $line[5], $line[6], $line[7], $line[8] , $line[9]) );
     push ( @printable, join( "\t", $line[0], $line[1], $line[2], $line[3], $line[10], $line[4], $line[5], $line[6], $line[7], $line[8] , $line[9]) );
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tStgPoolName\tDeviceClass\tColl\tEstCap{RIGHT}\tActUtil{RIGHT}\tPctUtil{RIGHT}\tPctMig{RIGHT}\tHigh{RIGHT}\tLow{RIGHT}\tRecl{RIGHT}\tNextStgPool", &addLineNumbers( @printable ) );

    return 0;

};
&defineAlias( 'estg',    'show estgp' );
&defineAlias( 's estg',  'show estgp' );
&defineAlias( 'sh estgp', 'show estgp' );


#######################
#SHow dbStatus ##################################################################################################
#######################

&msg( '0110D', 'SHow dbstatus' );
$Commands{&commandRegexp( "show", "dbstatus" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow dbstatus Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }
 # my $stg = $3;
  
  my @query = &runTabdelDsmadmc("select date(start_time), time(start_time),time(end_time),timestampdiff(4, char(end_time - start_time)), bytes, successful, number from summary where start_time>=current_timestamp - 30 days  and  activity='FULL_DBBACKUP' order by 1");
  return if ( $#query < 0 );

  &setSimpleTXTOutput();
  
      my @printable;

    foreach ( @query ) {
      my @line = split ( /\t/ );
      $line[4] = &byteFormatter ( $line[4], 'B' );
	  
	   if ( $line[5] eq "NO")   {
          $line[5] = &colorString( "$line[5]", "BOLD RED" )
		  }

	   push ( @printable, join( "\t", $line[0], $line[1], $line[2], $line[3], $line[4], $line[5]) );
	  }
  &universalTextPrinter( "#{%3s}\tDate\tStart Time\tEnd Time\tDuration (min)\tTotal Backed Up\tSucessful", &addLineNumbers( @printable) );
  return 0;


};
&defineAlias( 'sh volr',    'show volreclaim' );


##########################
# Show Deduppping 
##########################
$Commands{qr/^(show)\s*(deduppending, "")(\S*)/i} = sub {
  my @content = &runTabdelDsmadmc("show deduppending");
  #$LastCommandType = 'ASSOC';

  &universalTextPrinter("Date/Time\tMessage",@content);
  return 0;
};


#######################
# SHow DRtapes ##################################################################################################
#######################

&msg( '0110D', 'SHow DRTapes' );
$Commands{&commandRegexp( "show", "DRTapes" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow DRTapes Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }


  my @query = &runTabdelDsmadmc("select Volume_name, date(upd_date) as date, state, voltype from drmedia where state='COURIERRETRIEVE' or state='COURIER' order by 3");
  return if ( $#query < 0 );

  &setSimpleTXTOutput();

  &universalTextPrinter( "#{RIGHT}\tVolume Name\tDate\tState\tVolume Type", &addLineNumbers( @query ) );

  return 0;

};


1;
