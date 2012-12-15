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

#######################
# SHow ASSOciations ##################################################################################################
#######################

&msg( '0110D', 'SHow ASSociation' );
$Commands{&commandRegexp( "show", "association" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow ASSociation Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

  $LastCommandType = 'ASSOC';

  my @query = &runTabdelDsmadmc("select DOMAIN_NAME,SCHEDULE_NAME,NODE_NAME from associations where NODE_NAME like upper('%$_[2]%')");
  return if ( $#query < 0 );

  &setSimpleTXTOutput();

  &universalTextPrinter( "#{RIGHT}\tDomain\tSchedule\tNode Name", &addLineNumbers( @query ) );
  return 0;

};

################################
# DAssoc (Delete Associations) ################################################################################################################
################################

&msg( '0110D', 'DElete ASSociations' );
$Commands{&commandRegexp( "delete", "associations" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "DElete ASSociations Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    if ( $LastCommandType ne 'ASSOC' ) {
      # print "No schedule association to delete. The previous command type was not [ASSOC]. Use acceptable command before it!\n";
      # route back this command now
      return 1;
    }

    my $number = $3;
    
    if ( $number eq '' ) {
        &msg ( '0030E' );
        return 0;
    }
    $number--;

    my @return;

    my @line = split ( /\t/, $LastResult[$number] );

    &setSimpleTXTOutput();
    &universalTextPrinter( "NOHEADER", &runDsmadmc( "delete assoc $line[1] $line[2] $line[3]") );

    return 0;
};

#######################
# SHow TRAnsverrate ##################################################################################################
#######################

&msg( '0110D', 'SHow TRAnsverrate' );
$Commands{&commandRegexp( "show", "transverrate" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow TRAnsverrate Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

  $LastCommandType = 'ATRANSVERRATE';
  if ( $TSMSeverStatus{VERSION} > 5 ) {
    &msg("0051E", "5");
    return 0;
  }
    
  my @query = &runTabdelDsmadmc("select entity, schedule_name, SUM(AFFECTED) as NUM_OF_FILES, cast(SUM((END_TIME - START_TIME)) seconds as decimal) as BACKUP_WINDOW_SEC, SUM(CAST((BYTES) as DECIMAL )) as M_BYTES, cast(((SUM(CAST((BYTES/1024/1024 ) as DECIMAL(18,5)))) / (cast(SUM((END_TIME - START_TIME)) seconds as decimal (18,5)))) as DECIMAL(18,0)) as MBsec from summary where schedule_name in (select schedule_name from associations) and (start_time >= current_timestamp - 1 day) and (END_TIME <= current_timestamp - 0 day) group by entity, schedule_name order by MBsec desc", "select_client_speed_from_summary");
  return if ( $#query < 0 );
  
  if ( $ParameterRegExpValues{HISTORY} ) {

        my @archive = &initArchiveRetriever ( 'select_client_speed_from_summary' );
        return 0 if ( $#archive < 0 );

        while ( 1 ) {

            my @printable;
      
            foreach ( @archive ) {
                my @line = split ( /\t/ );
                $line[3] = &timeFormatter ( $line[3], 's' );
                $line[4] = &byteFormatter ( $line[4], 'B' );
          
                push ( @printable, join( "\t", $line[0], $line[1], $line[2], $line[3], $line[4], $line[5] ) );
            }
          
            &setSimpleTXTOutput();
            &universalTextPrinter( "NodeName\tSchedule_name\t#Files{RIGHT}\tTime{RIGHT}\tSize{RIGHT}\tMB/S{RIGHT}", @printable );

            @archive = &archiveRetriever();
            last if ( $#archive < 0 );

        }

    }
    else {

        my @printable;
      
        foreach ( @query ) {
            my @line = split ( /\t/ );
            $line[3] = &timeFormatter ( $line[3], 's' );
            $line[4] = &byteFormatter ( $line[4], 'B' );
      
            push ( @printable, join( "\t", $line[0], $line[1], $line[2], $line[3], $line[4], $line[5] ) );
        }
      
        &setSimpleTXTOutput();
        &universalTextPrinter( "NodeName\tSchedule_name\t#Files{RIGHT}\tTime{RIGHT}\tSize{RIGHT}\tMB/S{RIGHT}", @printable );
    }  
  
  return 0;

};

1;