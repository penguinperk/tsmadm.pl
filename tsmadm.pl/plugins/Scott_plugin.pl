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


##########################
# Show STGpools Enhanced #
##########################
&msg( '0110D', 'SHow ESTGpools' );
$Commands{&commandRegexp( "show", "estgpools" )} = sub {

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




$Commands{qr/^(show)\s*(deduppending, "")(\S*)/i} = sub {
  my @content = &runTabdelDsmadmc("show deduppending");
  &universalTextPrinter("Date/Time\tMessage",@content);
  return 0;
};

1;
