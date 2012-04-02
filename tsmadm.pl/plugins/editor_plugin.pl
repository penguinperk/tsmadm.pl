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
        print "SHow Scripts name and description in a table\n";
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

    my $PARAM = "";
    $PARAM = $3 if ( defined($3) );
    
    if ($PARAM eq ""){
        &msg("0030E");
        return 0;
    }
    my $scrName = uc($PARAM);
    my $file    = "$Settings{SCRIPTS}/".$scrName."_".$TSMSeverStatus{SERVERNAME}.".scr";
    my @content =
      &runTabdelDsmadmc("select line,command from scripts  where NAME='$scrName' order by line");
    if ( $#content != -1 || $LastErrorcode ){
        &saveScript($PARAM);
    }
    
    if ($OS_win)
    {
	system( "cmd /c start $Settings{EDITOR} $file" );
    }
    else
    {
        system( "$Settings{TERMINAL} -e $Settings{EDITOR} $file" );
    }
    
    &loadScript($PARAM);
    
    $LastCommandType = 'EDITSCRIPT';
    
    return 0;

};

####################
# EDit SCRipt #####################################################################################################
###################$
&msg( '0110D', 'Save SCRipt' );
$Commands{&commandRegexp( "save", "script", 2, 3 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "Save a Script to the $Settings{SCRIPTS} folder!\n";
        print "--------\n";
        $LastCommandType = "HELP";
        return 0;
    }

    my $PARAM = "";
    $PARAM = $3 if ( defined($3) );
    
    if ($PARAM eq ""){
        &msg("0030E");
        return 0;
    }
    
    return &saveScript($PARAM);

};

&msg( '0110D', 'Load SCRipt' );
$Commands{&commandRegexp( "load", "script", 2, 3 )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "Load a Script from the $Settings{SCRIPTS} folder!\n";
        print "--------\n";
        $LastCommandType = "HELP";
        return 0;
    }

    my $PARAM = "";
    $PARAM = $3 if ( defined($3) );
    if ($PARAM eq ""){
        &msg("0030E");
        return 0;
    }
    return loadScript($PARAM);
};


sub saveScript($){
    my $scrName = uc($_[0]);
    my $file    = "$Settings{SCRIPTS}/".$scrName."_".$TSMSeverStatus{SERVERNAME}.".scr";
    my @content =
      &runTabdelDsmadmc("select line,command from scripts  where NAME='$scrName' order by line");
    if ( $#content < 0 || $LastErrorcode ){
        &msg("0036E", $scrName);
        return 0;
    }
    open( FILE, ">", $file ) or die;
    foreach ( @content ) {
        my @line = split ( /\t/ );
        print FILE $line[1]."\n" if (defined $line[1]);
    }
    close(FILE) or die;
    $LastCommandType = 'SAVESCRIPT';
    return 0;
}

sub loadScript($){
    my $scrName = uc($_[0]);
    my $file    = "$Settings{SCRIPTS}/".$scrName."_".$TSMSeverStatus{SERVERNAME}.".scr";
    if (! -e $file){
        &msg("0035E", $TSMSeverStatus{SERVERNAME}, $scrName);
        return 0;
    }
    my @content = &runTabdelDsmadmc("select command from scripts where NAME='$scrName'");
    my $wasIt = 0;
    if ( $#content >= 0  ){
        &msg("0046I", $scrName);
        my $answer = <STDIN>;
        if ($answer !~ m/yes/i){
            return 0;
        } 
        $wasIt = 1;   
    }
    open( FILE, "<", $file ) or die;
    &runDsmadmc("define script tsmadm.pl_tmp_$scrName");
    my $i = 5;
    foreach ( <FILE> ) {
        chomp;
        &runDsmadmc("update script tsmadm.pl_tmp_$scrName '$_' line=$i");
        if ( $LastErrorcode ){
            &msg("0037E",$i/5);
            &runDsmadmc("delete script tsmadm.pl_tmp_$scrName");
            return 0;
        }
        $i = $i + 5 ;
    }
    close(FILE) or die;
    if ($wasIt == 1){
       &runDsmadmc("delete script $scrName");
    }
    &runDsmadmc("rename script tsmadm.pl_tmp_$scrName $scrName");
    if ( $LastErrorcode ){
        &msg("0038E", $scrName);
    }
    $LastCommandType = 'LOADSCRIPT';
    return 0;
}

1;
