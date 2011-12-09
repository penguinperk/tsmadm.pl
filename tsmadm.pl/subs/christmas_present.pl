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

sub christmasTree () {
 
    my $extraspace = sprintf("%*s", ($Settings{TERMINALCOLS}/2 ) - 26, "");
    
    my $screen = "";
    $screen .= $extraspace."           *             ,\n";
    $screen .= $extraspace."                       _/^\\_\n";
    $screen .= $extraspace."                      <  +  >\n";
    $screen .= $extraspace."     *                 /.-.\\         *\n";
    $screen .= $extraspace."              *        `/&\\`                   *\n";
    $screen .= $extraspace."                      ,@.*;@,\n";
    $screen .= $extraspace."                     /_o.I %_\\    *\n";
    $screen .= $extraspace."        *           (`'--:o(_@;\n";
    $screen .= $extraspace."                   /`;--.,__ `')             *\n";
    $screen .= $extraspace."                  ;@`o % O,*`'`&\\\n";
    $screen .= $extraspace."            *    (`'--)_@ ;o %'()\\      *\n";
    $screen .= $extraspace."                 /`;--._`''--._O'@;\n";
    $screen .= $extraspace."                /&*,()~o`;-.,_ `\"\"`)\n";
    $screen .= $extraspace."     *          /`,@ ;+& () o*`;-';\\\n";
    $screen .= $extraspace."               (`\"\"--.,_0  \+% \@' &()\\\n";
    $screen .= $extraspace."               /-.,_    ``''--....-'`)  *\n";
    $screen .= $extraspace."          *    /@%;o`:;'--,.__   __.'\\\n";
    $screen .= $extraspace."              ;*,&(); @ % &^;~`\"`o;@();         *\n";
    $screen .= $extraspace."              /(); o^~; & ().o@*&`;&%O\\\n";
    $screen .= $extraspace."              `\"=\"==\"\"==,,,.,=\"==\"===\"`\n";
    $screen .= $extraspace."    __________.----.(\-''#####---...___...-----._\n";
    $screen .= $extraspace."\n";
    
    #$screen .= $extraspace."         '`         \)_`\"\"\"\"\"`\n";
    #$screen .= $extraspace."                 .--' ')\n";
    #$screen .= $extraspace."               o(  )_-\\\n";
    #$screen .= $extraspace."                 `\"\"\"` `\n";
    #ASCII art ftom http://www.chris.com/ascii/index.php?art=holiday%2Fchristmas%2Ftrees

    return $screen;
    
    return 1;
}

########################################################################################################################

1;