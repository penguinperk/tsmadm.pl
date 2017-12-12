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

#####################
# SHow VMBACKupstat ##################################################################################################
#####################

&msg( '0110D', 'SHow VMBACKupstat' );
$Commands{&commandRegexp( "show", "vmbackupstat" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow VMBACKupstat Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

  $LastCommandType = 'VMBACKUP';

  my @query = &runTabdelDsmadmc("select rpad(schedule_name,15)AS SCHEDULE,rpad(sub_entity,15) AS VMGUEST,DATE(start_time) AS STARTD, TIME(START_time)AS STARTT,DATE(end_time) AS ENDT, TIME(end_time)AS ENDT, rpad(activity,15) AS TYPE,rpad(entity,20) AS PROXYNODE from summary_extended where activity_details='VMware' and end_time>(current_timestamp-1 day) and successful='NO' and failed=1"); return if ( $#query < 0 );

  &setSimpleTXTOutput();

  &universalTextPrinter( "#{RIGHT}\tSchedule\tVM\tStartd\tStartT\tEndd\tEndt\tType\tproxyNode", &addLineNumbers( @query ) );
  return 0;

};

#####################
# SHow VMALLBACKupstat ##################################################################################################
#####################

&msg( '0110D', 'SHow VMALLBACKupstat' );
$Commands{&commandRegexp( "show", "vmallbackupstat" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow VMALLBACKupstat Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

  $LastCommandType = 'VMBACKUP';

  my @query = &runTabdelDsmadmc("select Rpad(successful,5) AS RESULT,rpad(sub_entity,30)AS VM,rpad(schedule_name,25) AS SCHEDULE,Date(start_time)AS DATE,TIME(start_time) AS STARTT,TIME(end_time) AS ENDT,bytes/1024/1024 AS MB,rpad(activity_type,20) AS BKPTYPE,rpad(entity,20)AS PROXYNODE from summary_extended where (activity_details='VMware') and (end_time> current_timestamp-1 day) order by result,MB"); return if ( $#query < 0 );
  &setSimpleTXTOutput();

  &universalTextPrinter( "#{RIGHT}\tSucc\tVM\tScheduke\tStartd\tStartT\tEndt\tMB\tType\tproxyNode", &addLineNumbers( @query ) );
  return 0;

};

1;