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

&msg( '0110D', 'editor commands' );

####################
# SHow SCRIpts #####################################################################################################
###################$
&msg( '0110D', 'SHow SCRIpts' );
$Commands{&commandRegexp( "show", "scripts", 2, 4 )} = sub {

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

    my @query = &runTabdelDsmadmc( "select name, description from SCRIPT_NAMES" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'SCRIPTS';

    &setSimpleTXTOutput();
    &universalTextPrinter( "Name\tDescription\t", @query );

    return 0;

};

####################
# EDit SCRipt #####################################################################################################
###################$
&msg( '0110D', 'EDit SCRipt' );
$Commands{&commandRegexp( "edit", "script", 2, 3 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "EDit SCRipt Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @query = &runTabdelDsmadmc( "q script" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'EDITSCRIPT';
    
    return 0;

};

1;
