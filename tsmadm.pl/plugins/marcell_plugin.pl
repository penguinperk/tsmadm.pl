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

my @temp;

$Commands{qr/^(show|^sho|^sh)\s+(nodes|node|nod|no)\b\s*(\S*)$/i} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "show node Help!\n";
        print "--------\n";
        return 0;
    }

    my @libvolumes = &runTabdelDsmadmc(
"select NODE_NAME, PLATFORM_NAME, DOMAIN_NAME, TCP_NAME, TCP_ADDRESS from nodes"
    );
    &setSimpleTXTOutput();
    @libvolumes = addLineNumbers(@libvolumes);
    &universalTextPrinter(
"#{%3s}[RED]\tNode Name\tPlatform\tDomain\tHostname{%MAX.MAXs}\tIP Address",
        @libvolumes
    );
    @temp = @libvolumes;
    return 0;
};

$Commands{qr/^(login)\s*(\S*)/i} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "show node Help!\n";
        print "--------\n";
        return 0;
    }

    print "$2 = $temp[$2]";
    return 0;
};

$Commands{qr/^(debug)\s*(\S*)/i} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "show node Help!\n";
        print "--------\n";
        return 0;
    }
    my $PARAM = $2 if ( defined($2) );
    if ( defined($PARAM) && $PARAM ne "" ) {
        if ( $PARAM =~ m/^ON$/i || $PARAM =~ m/^OFF$/i ) {
            $Settings{DEBUG} = 1 if ( $PARAM =~ m/^ON$/i );
            $Settings{DEBUG} = 0 if ( $PARAM =~ m/^OFF$/i );
        }
        else {
            &msg( "0001E", "debug" );
        }
    }
    elsif ( !defined $Settings{DEBUG} || !$Settings{DEBUG} ) {
        $Settings{DEBUG} = 1;
    }
    else {
        $Settings{DEBUG} = 0;
    }
    my $SWITCH = ( $Settings{DEBUG} ) ? "ON" : "OFF";
    &msg( "0018I", "$SWITCH" );
    return 0;
};

$Commands{qr/^(terminal)\s*(\S*)/i} = sub {
    if ( $2 eq "" ) {
        &msg( "0019I", $Settings{TERMINAL} );
        return 0;
    }
    else {
        if ($OS_win) {
            &msg( "0020E", "Windows" );
            return 0;
        }
        $Settings{TERMINAL} = $2;
        &msg( "0019I", $Settings{TERMINAL} );
        return 0;
    }
};

$Commands{qr/^(history)\s*(\S*)/i} = sub {
  @temp = @History;
  my $j = 0;
  foreach (@temp) {$temp[$j] =~ s/\t/    /g; $j++;} ## a kiiro miatt a TAB-okat kicserelem szóközkre
  my @temp = addLineNumbers(@temp);
  &universalTextPrinter(" #\tCommand",@temp);
  return 0;
};

$Commands{qr/^(show)\s*(actlog)(\S*)/i} = sub {
  my @content = &runTabdelDsmadmc("q actlog begint=-00:01");
  &universalTextPrinter("Date/Time\tMessage",@content);
  return 0;
};


1;
