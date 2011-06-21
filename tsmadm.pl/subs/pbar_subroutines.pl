#!/usr/bin/perl

use strict;
use warnings;

###########################################
# G L O B A L  V A R S  F R O M tsmadm.pl #
###########################################

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

######################
# L O C A L  V A R S #
######################

# +------+
# | pbar |
# +------+

my %init = (
    'beginText' => "",
    'maxValue'  => 0,
    'endText'   => "",
    'barChar'   => '='
);

my $r_init = \%init;

#########################
# S U B R O U T I N E S #
#########################

# +------+
# | pbar |
# +------+

# USAGE:
# (1) Initialize progress bar:
# 	&pbarInit(<before text>, <maximum value>, <end text>)
# (2) Update progress bar:
#	&pbarUpdate(<current value>)
#
# MISC. INFO:
# (a) progress bar character is '=';
# (b) in order for the bar to extend to its full length when job is finished, make sure you call pbarUpdate with the maximum value given at initialization time.
# (c) to insert the current percentage value (including the % sign) into either $beginText or $endText or both, use the %% symbol.

sub pbarInit {
################################################################################
#
#  Owner:					perec
#  Last modified:			2011.05.04
#  Called by:				various functions
#  Called with parameters:	array(beginText,maxValue,endText)
#  Calls:					pbarAssemble
#  Returns:					NONE
#  Function:				Sets up a progress bar,
#							calculates initial values,
#							prints first bar.	
#
################################################################################

    my $percents = '%%';
    my ( $beginText, $maxValue, $endText ) = @_;
    $r_init->{'beginText'} = $beginText;
    my $beginPlus1 = 0;
    $beginPlus1 = 1 if ( index( $beginText, $percents ) != -1 );
    $r_init->{'maxValue'} = $maxValue;
    $r_init->{'endText'}  = $endText;
    my $endPlus1 = 0;
    $endPlus1 = 1 if ( index( $endText, $percents ) != -1 );

    # update terminal attributes
    &updateTerminalSettings;

    # Expand hash
    $r_init->{'currentV'} = 0;    # Current value, defaults to 0
    $r_init->{'currentC'} = 0;    # Current value in chars (0..totalC)
    $r_init->{'percentV'} = 0;    # Current value in percents, defaults to 0%
    my $MSWin32Correction = 0;
    $MSWin32Correction = 1 if ($OS_win);
    my $tC =
      $Settings{TERMINALCOLS} -
      $MSWin32Correction -
      length( $r_init->{'beginText'} ) -
      $beginPlus1 -
      length( $r_init->{'endText'} ) -
      $endPlus1;
    $r_init->{'totalC'} = $tC;    # total bar length in chars, calculated
    my $bS = $r_init->{'maxValue'} / $tC;
    $r_init->{'barStep'} = $bS;    # value step of one char, calculated

    my $firstBar = &pbarAssemble($r_init);

    $| = 1;                        # disable output buffering
    print $firstBar;
}

sub pbarUpdate {

    my ($update) = @_;
    $r_init->{'currentV'} = $update;

    $r_init->{'percentV'} = int( $update / $r_init->{'maxValue'} * 100 );

    my $prevC = $r_init->{'currentC'};    # store current C value before recalc
    if ( $update != $r_init->{'maxValue'} ) {
        $r_init->{'currentC'} =
          int( $r_init->{'currentV'} / $r_init->{'barStep'} );
    }
    else {
        $r_init->{'currentC'} = $r_init->{'totalC'};
    }
    if ( $prevC != $r_init->{'currentC'} ) {

        # we only need to redraw if there is a visible change
        my $updatedBar = &pbarAssemble($r_init);
        print "\r$updatedBar";
        print "\n" if ( $r_init->{'currentV'} == $r_init->{'maxValue'} );
    }
}

sub pbarAssemble {

    my $newBar;
    my $buff;
    my $match;

    $match = sprintf( "%3s", $r_init->{'percentV'} );

    $buff = $r_init->{'beginText'};
    $buff =~ s/%%/$match/g;

    # add begin text
    $newBar = $buff;

    # add as many bar unites as necessary
    $newBar .= $r_init->{'barChar'} x $r_init->{'currentC'};

    # fill the bar with spaces up to maximum
    $newBar .= ' ' x ( $r_init->{'totalC'} - $r_init->{'currentC'} );

    $buff = $r_init->{'endText'};
    $buff =~ s/%%/$match/g;

    # add end text
    $newBar .= $buff;

    # return assembled bar
    return $newBar;
}

1;
__END__
