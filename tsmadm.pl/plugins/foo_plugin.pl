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

&msg( '0110D', 'FOOooo' );
$Commands{&commandRegexp( "fooooo", "" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print <<FOOHELPEND;
----------------
Help of foo! ;-)
----------------
   __
  / _| ___   ___
 | |_ / _ \\ / _ \\
 |  _| (_) | (_) |
 |_|  \\___/ \\___/

Enjoy it!
FOOHELPEND

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = "FOO";

    &setSimpleTXTOutput();
    &universalTextPrinter( "#\tValue", &addLineNumbers( @_ ) );

    print "foo fighter!\n";

    return 0;

};
&defineAlias( 'fo',  'foo' );

1;