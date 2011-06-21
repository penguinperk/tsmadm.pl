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

my $process_time;
my $status;

# show backup
# show recl
# show move
# show migr

####################
# Show BACkupstgp  #####################################################################################################
####################
&msg( '0110D', 'SHow BACkup' );
$Commands{&commandRegexp( "show", "backup" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow BACkup Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @return;
    $LastCommandType = 'GENERAL';

    my $extraparam = $3.$4.$5;

    # Search started migrations
    my @query = &runTabdelDsmadmc( "q act begint=-08:00 msg=1210 ".$extraparam );
    return if ( $#query < 0 );

    &pbarInit( "COLLECTING DATA |", scalar( @query ), "|");

    my $i = 1;
    foreach ( @query ) {

        my @line = split(/\t/, $_);

        my $start_time = $line[0];
        my $stgpool_name = "";
        my $copystgpool_name = "";
        my $process = 0;
        #
        my $end_time = "";
        my $remark = "";

        my $endpart = "\t\t\t";

        &pbarUpdate( $i++ );

        if ( $line[1] =~ m/Backup\ of\ primary\ storage\ pool\ (\w+)\ to\ copy\ storage\ pool\ (\w+)\ started\ as\ process\ (\d+)\./ ) {

            $stgpool_name     = $1;
            $copystgpool_name = $2;
            $process          = $3;

            # 0986
            my @query = &runTabdelDsmadmc( "q act begint=-08:00 msg=0986 search='Process ".$process."' ".$extraparam );

            if ( $#query < 0 ) {

                # No match found
                $status = "UNKNOWN";
                $remark = "Not yet finished...";

                # 0985
                my @query = &runTabdelDsmadmc( "q act begint=-08:00 msg=0985 search='Process ".$process."' ".$extraparam );
                if ( $#query >= 0 ) {

                    my @line = split( /\t/, $query[0]);

                    $end_time = $line[0];

                    if ( $line[1] =~ m/BACKUP STORAGE POOL running in the \w+GROUND completed with completion state (\w+) at/ ) {
                        $status = $1;
                        $remark = "Check the activity log!";
                    }

                }

            }
            else {

                my @line = split(/\t/, $query[0]);

                $end_time = $line[0];

                $process_time = &convert_date($end_time) - &convert_date($start_time);

                $endpart = &parser( $line[1] );

            }
        }

        if ( $start_time =~ m/(\d\d\/\d\d\/\d\d\d\d\s*)/ ) {
            my $date = $1;
            $end_time =~ s/$date//;
        }

        push( @return, $start_time."\t".$end_time."\t".$stgpool_name."\t".$copystgpool_name."\t".$process."\t".$endpart.$remark );

    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "Starttime\tEndtime\tPrimarypool\tCopypool\tProc#\tFiles\tBytes{RIGHT}\tStatus\tRemark", @return );

    return 0;

};
&defineAlias( 's backup',  'show backup' );

########################################################################################################################

###############
# Show TIMIng ##########################################################################################################
###############
&msg( '0110D', 'SHow DISks' );
$Commands{&commandRegexp( "show", "timing" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow TIMing Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @return;

    $LastCommandType = 'GENERAL';

    my @query = &runTabdelDsmadmc('q event * * begind=-1 begint=16:00 endd=today endt=now f=d '.$3);
    return if ( $#query < 0 || $LastErrorcode );

    my @line;

    my $first_time;
    @line = split(/\t/, $query[0]);
    $first_time = &convert_date($line[3]);

    my $last_time;
    @line = split(/\t/, $query[$#query]);
    if ( $line[5] ne '' ) {
        $last_time = &convert_date($line[5]);
    }
    else {
        $last_time = &convert_date($line[3]);
    }

    &pbarInit( "PASS 1 |", scalar( @query ), "|");

    my $maxlength = 0;
    my $i = 1;
    foreach ( @query ) {
        my @line = split(/\t/);

        $line[7] = '?' if ( ! defined $line[7] );
        my $length = colorLength( ($i+1)." $line[1] $line[2] || $line[7]" );

        $maxlength = $length if ( $length > $maxlength );

        &pbarUpdate( $i );

        $i++;

    }

    my $size = $Settings{TERMINALCOLS} - $maxlength - 5; # 9

    my $quantum = ($size-1);
    $quantum = ($size-1)/($last_time-$first_time) if ( ($last_time-$first_time) > 0 );

    &pbarInit( "PASS 2 |", ($size-1), "|");

    # create an empty bar line
    my @emptybar;
    for ( my $i = 0; $i <= ($size-1); $i++ ) {
        $emptybar[$i] = ' ';
        &pbarUpdate( $i );
    }

    &pbarInit( "PASS 3 |", scalar( @query ), "|");

    $i = 1;
    for (@query) {
        my @line = split(/\t/);

        my @bar = @emptybar;

        &pbarUpdate( $i );

        $bar[int((&convert_date($line[3])-$first_time)*$quantum)] = 'S';

        if ( $line[6] =~ m/Future/i ) {
            &fill_bar(\@bar, int((&convert_date($line[3])-$first_time)*$quantum), ($size-1), 'f')
        }

        if ( $line[6] =~ m/Missed/i ) {
            &fill_bar(\@bar, int((&convert_date($line[3])-$first_time)*$quantum), ($size-1), 'M')
        }

        if ( $line[6] =~ m/(C|F)(ompleted|ailed)/i ) {
            &fill_bar(\@bar, int((&convert_date($line[3])-$first_time)*$quantum)+1, int((&convert_date($line[4])-$first_time)*$quantum)-1, 'w');
            &fill_bar(\@bar, int((&convert_date($line[4])-$first_time)*$quantum)+1, int((&convert_date($line[5])-$first_time)*$quantum)-1, 'r');

            $bar[int((&convert_date($line[4])-$first_time)*$quantum)] = 'A';
            $bar[int((&convert_date($line[5])-$first_time)*$quantum)] = "$1";
        }

        $line[7] = '?' if ( ! defined $line[7] );

        push( @return, join( "\t", ++$i, $line[1], $line[2], '|'.join('', @bar).'|', $line[7] ));

    }

    # "---\nS-ScheduleStart A-ActualStart r-Running C-Completed, F-Failed, M-Missed, f-furure\n";
    &setSimpleTXTOutput();
    &universalTextPrinter( "#\tScheduleName\tNodeName\tTiming\tRe", @return );

    return 0;

};

sub convert_date ($) {
  my $tmpdate = $_[0];

  return if ( ! defined $tmpdate || $tmpdate eq '' );

  $tmpdate =~ m/(\d\d)\/(\d\d)\/.*(\d\d) +(\d\d):(\d\d):(\d\d)/;
  return timelocal( $6, $5, $4, $2, $1-1, $3 );

};

sub fill_bar ( $$$$ ) {
    my $r_array   = $_[0];
    my $first_poz = $_[1];
    my $last_poz  = $_[2];
    my $value     = $_[3];

    for ( my $i = $first_poz; $i <= $last_poz; $i++ ) {
        @$r_array[$i] = $value;
    }
}

#####################
# local SUBroutines ####################################################################################################
#####################

sub parser ( $ ) {

  if ( $_[0] =~ m/running\ in\ the\ \w+GROUND\ processed\ (\d+)\ items\ for\ a\ total\ of\ (.+)\ bytes\ with\ a\ completion\ state\ of\ (\w+)\ at/ ) {

    my $processed_items = $1;

    my $total = $2;
    my $status = $3;

    $total =~ s/,//g;

    # MB/s
    my $speed = 0;
    $speed = int($total / 1024 / 1024 / $process_time) if ( $process_time > 0 ) ;

    my $comment = 'BAD!';
    $comment = '' if ( $speed < 1 ); #Override comment when zero

    if ( $speed > 60 ) {
      $comment = 'EXCELLENT!';
    }
    elsif ( $speed > 30 ) {
      $comment = 'GOOD!';
    }
    elsif ( $speed > 10 ) {
      $comment = 'POOR!';
    }

    return $processed_items."\t".&byteFormatter( $total, 'B' )."\t".$status."\t".sprintf ('Speed: %i MB/s %s',$speed,$comment);
  }
};

1;