#!/usr/bin/perl

use strict;
use warnings;
use MIME::Base64 ();

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

my $cipherKey = "3845307703096290674869301291068520826141172501386118369144311113210791127304530";

my $HistoryPointer;

sub commandSplitterParserExecuter ( $ ) {

    # command splitter
    if ( !defined( $_[0] ) ) {
        &msg( "0001E", "&commandSplitterParserExecuter" );
        return 2;
    }
    
    my $commandsTmp = "";
    foreach ( split( /\s*;\s*/, $_[0] ) ) {

        my $command = $_."ENDofCOMMAND"; # add 

        # aliases
        for my $key ( keys %Aliases ) {
            #last if ( $command =~ s/^\s*$key(ENDofCOMMAND|\ +)/$Aliases{$key}$1/i );
	    # Issue 5 solution from István
	    last if ( $command =~ s/^\s*$key(ENDofCOMMAND|\ +|\|)/$Aliases{$key}$1/i );
	    
	    #command routing reservation
	    last if ( $command =~ s/^\s*([\w_\-\.]+):\s*$key(ENDofCOMMAND|\ +|\|)/$1: $Aliases{$key}$2/i );
	    last if ( $command =~ s/^\s*\(([\w_\-\.]+)\)\s*$key(ENDofCOMMAND|\ +|\|)/\($1\) $Aliases{$key}$2/i );
        }

        $commandsTmp .= $command.";";

    }
    $commandsTmp =~ s/ENDofCOMMAND//g; # cleanup

    my @commands = split( /\s*;\s*/, $commandsTmp );

    foreach ( @commands ) {

        my $command = $_;

        &msg( "0003D", "$command" );

        if ( $command =~ /^\s*(quit|exit|bye|logout|end)/i ) {
	    &saveHistory;
            return 1;
        }

        # quoted regexp
	if ( $command =~ m/grep\s+"([a-zA-z0-9\|]+)"/ ) {

	    my $regexp = $1;
	    $regexp =~ s/\|/&ORGREP&/g;

	    $command =~ s/(grep\s+")([a-zA-z0-9\|]+)"/$1$regexp/;
	}

	# quoted commands
        my $quotedCommand = "";
        if ( $command =~ s/^\s*('|")(.+)('|")// ) {
            $quotedCommand = $2;
        }

        # cut the parameters
        for my $key ( keys %ParameterRegExps ) {
            my $value1 = $ParameterRegExps{$key};
            my $value2 = $ParameterRegExpValues{$key};

	    while ( $command =~ s/$value1// ) {

		#
		if ( defined($2) ) {
		    my $parameter = $2;
		    $parameter =~ s/\s+$//;
		    $ParameterRegExpValues{$key} .= ( !defined( $ParameterRegExpValues{$key} ) || $ParameterRegExpValues{$key} eq "" ) ? $parameter : '&ANDGREP&'.$parameter;
		}
		else {
		    $ParameterRegExpValues{$key} = 1;
		}
				
	    }
        }

#print &colorString( &textLine( "DEBUG: COMMAND RECEIVED. ", "-" ), "bold red" );
        &msg("0012D");

        # Parameter Debug
        my @array;
        for my $key ( keys %ParameterRegExps ) {
            my $value1 = $ParameterRegExps{$key};
            my $value2 =
              defined( $ParameterRegExpValues{$key} )
              ? &colorString( $ParameterRegExpValues{$key}, "BOLD GREEN" )
              : &colorString( "N/A",                        "RED" );

            #
            push( @array, "$key\t$value1\t$value2" );
        }

        if ( defined( $Settings{'DEBUG'} ) && $Settings{'DEBUG'} ) {
            $Settings{'DISABLEGREP'} = 1;
            &setSimpleTXTOutput();
            &universalTextPrinter( "KEY\tREGEXP\tVALUE", @array );

        }

        $command = $quotedCommand if ( $quotedCommand ne '' );    #

        #change command if alias is defined
#        for my $key ( keys %Aliases ) {
#            last if ( $command =~ s/^\s*$key\ /$Aliases{$key}/i );
#        }

        $command =~ s/\s*$//;                                     # cut the end
        $command .= ' ';                                          # extra space to separate wrong commands

#Debug
#print &colorString(  &textLine( "DEBUG: COMMAND EXECUTER [$command]. ", "-" ), "bold red" );
        my $repeat;
        my $sleep;

        if ( defined( $ParameterRegExpValues{REPEAT} ) && $ParameterRegExpValues{REPEAT} =~ m/(\d+)x(\d+)/ ) {
        	$repeat = $1;
        	$sleep  = $2;
        }
        elsif ( defined( $ParameterRegExpValues{REPEAT} ) && $ParameterRegExpValues{REPEAT} =~ m/(\d+)/ ) {
        	$repeat = $1;
        	$sleep  = 1;
        }
        else {
        	$repeat = 1;
            $sleep  = 0;
        }

        for ( my $i = 1 ; $i <= $repeat ; $i++ ) {
            &msg( "0013D", $command );
            if ( !&builtinCommandExecuter($command) ) {

                # debug message
            }
            elsif ( !&pluginCommandExecuter($command) ) {

                # debug message
            }
            else {

                # debug message
                &dsmadmcCommandExecuter($command);
            }
            sleep $sleep if ( $sleep >= 1 && $i < $repeat);
        }
        &msg("0011D");

        # reset it here
        %ParameterRegExpValues = ();

    }

    return 0;    # Done

}

sub builtinCommandExecuter( $ ) {

    my $command = $_[0];

    if ( $command =~ m/^\s*!\s*(.*)/ ) {
        system($1);
        return 0;
    }

    #
    return 1;    # not matched

}

sub pluginCommandExecuter( $ ) {

    my $command = $_[0];

    # plugin command
    for my $key ( keys %Commands ) {
        if ( $command =~ /$key/i ) {
            return &{ $Commands{$key} }( @_ );
        }
    }

    #
    return 1;    # not matched

}

sub dsmadmcCommandExecuter( $ ) {

    my $command = $_[0];

    &setSimpleTXTOutput();
    &universalTextPrinter( "NOHEADER", &runDsmadmc($command) );

}

sub isHelpParameter () {

    my $parameter;

    foreach (@_) {
        if ( defined $_ ) {
            $parameter = $_;
        }
        else {
            $parameter = "";
        }
        return 1 if ( $parameter =~ m/\?|-h|-help|help/ );

        # print $_;
        # return 1 if ( m/\?|-h|-help|help/ );
    }

}

############################################
# reLoad external Exclude list and plugins
############################################
sub reLoadPlugins () {

    %Commands = ();

    for ( glob("$Dirname/plugins/*.pl") ) {
        &msg( '0111D', $_ );
        do $_ || die("TOTAL FATAL: $!, check this file: [$_] generated");
    }

}

##########################################################################################
# Return formatted time
##########################################################################################
sub msgSpentTime ( $ ) {
    my $time = $_[0];

    my $sec  = $time % 60;
    my $min  = ( $time / 60 ) % 60;
    my $hour = ( $time / 3600 ) % 24;
    my $day  = int( $time / 86400 );

    if ( $day == 0 ) {
        return sprintf( "%02d:%02d:%02d", $hour, $min, $sec );
    }
    elsif ( $day == 1 ) {
        return sprintf( "%d day, %02d:%02d:%02d", $day, $hour, $min, $sec );
    }
    else {
        return sprintf( "%d day(s), %02d:%02d:%02d", $day, $hour, $min, $sec );
    }

}

##########################################################################################
# loadFileToHash
##########################################################################################
sub loadFileToHash ( $ ) {
    
    my $filename = $_[0];
    my %returnHash;
    if ($OS_win) {
	$returnHash{HOMEDIRECTORY} = $ENV{HOMEDRIVE} . $ENV{HOMEPATH};
    } else {
	$returnHash{HOMEDIRECTORY} = $ENV{HOME};
    }
    
    open my $HASHFILE, "+<:encoding(utf-8)", "$filename"
      or die "File ($filename) open error: $!";

    while (<$HASHFILE>) {
        chomp;
        next
          if /^(\s)*$/
              or /^#.*/
        ; # skipping empty or commented (the first character is a hashmark) lines
        my ( $hash_key, $hash_value ) = split( /=/, $_, 2 );
        $hash_key   =~ s/^\s*|\s*$//g;
        $hash_value =~ s/^\s*|\s*$//g;
        print "FILE->HASH Content: $hash_key = $hash_value\n"
          if ( defined( $Settings{'DEBUG'} ) && $Settings{'DEBUG'} );
        $returnHash{ uc($hash_key) } = $hash_value;
    }
    close($HASHFILE);

    return %returnHash;
}

##########################################################################################
# msg
##########################################################################################
#sub msg ( $@ ) {
#	print ( &msgString( @_ ) );
#}

##########################################################################################
# msg
##########################################################################################
sub msg ( $@ ) {

    return if ( $Settings{QUIET} );

    my $messageID         = "";
    my @messageParameters = "";
    my $msg;
    my $toprint;
    my $prefix = "TADM";
    if ( defined( $_[0] ) ) {
        $messageID = uc( $_[0] );
        if ( !$Messages{$messageID} ) {
            &msg( "0002E", $messageID,
                "$Dirname/languages/" . $Settings{LANGUAGE} . ".txt" );
        }
        splice( @_, 0, 1 );
        @messageParameters = @_ if ( defined(@_) );
    }
    else {
        &msg( "0001E", "&msg" );
    }

    return 0
      if ( $messageID =~ m/\d\d\d\dD/
        && ( !defined( $Settings{'DEBUG'} ) || !$Settings{'DEBUG'} ) );

    if (   $messageID =~ m/\d\d\d\dD/
        && defined( $Settings{'DEBUG'} )
        && $Settings{'DEBUG'} )
    {
        $toprint = sprintf(
            $prefix . $messageID . " " . $Messages{$messageID} . " ",
            @messageParameters
        );

        # cut it 
        if ( length($toprint) > $Settings{TERMINALCOLS} - 1 ) {
            $toprint = substr( $toprint, 0, $Settings{TERMINALCOLS} - 1 );
        }

        $msg = ( &colorString( &textLine( $toprint, "-" ), "CYAN" ) );
    }
    elsif ( $messageID =~ m/\d\d\d\dE/ ) {
        $toprint = sprintf(
            $prefix . $messageID . " " . $Messages{$messageID} . " ",
            @messageParameters
        );

        # cut it
        if ( length($toprint) + 1 > $Settings{TERMINALCOLS} - 1 ) {
            $toprint = substr( $toprint, 0, $Settings{TERMINALCOLS} - 1);
        }

        $msg = &colorString( $toprint . "\n", "BOLD RED" );
    }
    elsif ( $messageID =~ m/\d\d\d\dW/ ) {
        $toprint = sprintf(
            $prefix . $messageID . " " . $Messages{$messageID} . " ",
            @messageParameters
        );
        $msg = &colorString( $toprint . "\n", "BOLD YELLOW" );
    }
    else {
        $toprint = sprintf(
            $prefix . $messageID . " " . $Messages{$messageID} . " ",
            @messageParameters
        );
        $msg = $toprint . "\n";
    }
    print $msg;
    if ( defined( $Settings{'DEBUG'} ) && $Settings{'DEBUG'} ) {
        my $debugFile = "tsmadmDebugLog.txt";
        open my $DEBUGFILE, ">>$debugFile" or die;
        print $DEBUGFILE localtime(time) . " " . $toprint . "\n";
        close $DEBUGFILE or die;
    }
}

sub colorLength( $ ) {
    my $str = $_[0];
    my $cnt = 0;

    $str =~ s/\e\[.+?m//g;
    while ( $str =~ /./g ) { $cnt++ }

    return $cnt;
}

sub colorExtraLength( $ ) {
    my $str = $_[0];

    return ( length( $str ) - &colorLength( $str ) );
}

sub colorSubstr( $$ ) {

    # usage: substr($text, 0, &colorSubstr( $text, 20) ).&colorString( "", "WHITE")

    my $str    = $_[0];
    my $length = $_[1];

    my $switch = 0; #escape

    my $counter1 = 0;
    my $counter2 = 0;

    foreach ( split ( //, $str ) ) {

      $counter2++;

      if ( !$switch && $_ =~ m/\e/ ) {
        $switch = 1;
        next;
      }
      elsif ( $switch && $_ eq "m" ) {
        $switch = 0;
        next;
      }

      $counter1++ if ( !$switch );

      last if ( $counter1 == $length );

    }

    return ( $counter2 );
}

sub colorString( $$ ) {

    my $string = $_[0];

    my $color;

    if (!  defined $_[1] ) {
	$color = "RESET"
    } else {
	$color  = $_[1];
    };

    if ( !$Settings{NOCOLOR} && !$ParameterRegExpValues{NOCOLOR} && $color ne "" ) {

        # color engine V1.0
        my $tmp = colored( "", $color );
        $string =~ s/\e\[0m/$tmp/g;

        # return  colored( $string, $color );
        if ( defined( $Settings{DEFAULTCOLOR} ) ) {
            return colored( $string, $color )
              . sprintf( color $Settings{DEFAULTCOLOR} );
        }
        else {
            return colored( $string, $color );
        }

    }
    else {

        return $string;

    }

}

sub colorString2( $$ ) {
    my $string = $_[0];
    my $color  = $_[1];

    if ( !$ParameterRegExpValues{NOCOLOR} && $color ne "" ) {

        # return  colored( $string, $color );
        if ( defined( $Settings{DEFAULTCOLOR} ) ) {
            return colored( $string, $color );
        }
        else {
            return colored( $string, $color );
        }
    }
    else {
        return $string;
    }
}

sub sendMail() {

    print "Levél küldése $_[0] -nak \n";

}

#######################################################################################################################
# textLine
#######################################################################################################################
sub textLine ($$) {

    my $text = $_[0];
    my $pattern = substr( $_[1], 0, 1 );    # use only 1 character if got more

    my $return;

    my $textLength = &colorLength($text);

    if ( $textLength > $Settings{TERMINALCOLS} ) {

        # if longer than the screen
        # cut it
        return substr( $text, 0, $Settings{TERMINALCOLS} );
    }
    else {

        # if shorter than the screen add extra pattern to the end
        my $line = "";
        for (
            my $i = 1 ;
            ( $Settings{TERMINALCOLS} - $textLength ) >= $i + 1 ;
            $i++
          )
        {
            $line .= $pattern;
        }
        return $text . $line . "\n";
    }

}

#######################################################################################################################
# showRuler
#######################################################################################################################
sub showRuler () {
#print &colorString( &textLine( "DEBUG: OUR TERMINAL PARAMETER IS: [Settings{TERMINALCOLS} x Settings{TERMINALROWS}] ", "-" ), "bold red" );
    &msg( "0010D", $Settings{TERMINALCOLS}, $Settings{TERMINALROWS} );
    my $x;
    my $c;

    # 100
    for ( $x = 1, $c = 1; $Settings{TERMINALCOLS} - 1 >= $x; $x++ ) {
        if ( $x % 100 == 0 ) {
            $c = 0 if ( $c == 10 );
            print "$c";
            $c++;
        }
        else {
            print ' ';
        }
    }
    print "\n";

    # 10
    for ( $x = 1, $c = 1; $Settings{TERMINALCOLS} - 1 >= $x; $x++ ) {
        if ( $x % 10 == 0 ) {
            $c = 0 if ( $c == 10 );
            print "$c";
            $c++;
        }
        else {
            print ' ';
        }
    }
    print "\n";

    # 1
    for ( $x = 1; $Settings{TERMINALCOLS} - 1  >= $x; $x++ ) {
        print $x % 10;
    }
    print "\n";

}

#######################################################################################################################
# defineAlias
#######################################################################################################################
sub defineAlias( $$ ) {

    &msg ( '0060D', $_[0], $_[1] );

    $Aliases{"$_[0]"} = "$_[1]";
}

#######################################################################################################################
# createTimestamp
#######################################################################################################################
sub createTimestamp( ) {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime( time() );

    #msg
    return sprintf "%4d%02d%02d_%02d%02d%02d", $year + 1900, $mon + 1, $mday,
      $hour, $min, $sec;
}

#######################################################################################################################
# saveArray2File
#######################################################################################################################
sub saveArray2File( $$@ ) {

    my $directory = $_[0];
    my $filename  = $_[1];
    splice( @_, 0, 2 );
    my @array = @_;

    mkpath $directory or die if ( !-d "$directory" );

    open( my $FH, ">>$directory/$filename" ) or die "Can't open $filename: $!";
    foreach (@array) {
        print $FH "$_\n";
    }
    close $FH;

}

#######################################################################################################################
# getTSMStatus
#######################################################################################################################
sub getTSMStatus() {

    if ( $Settings{AUTOCONNECT} ) {

        my @filedNames = (
            "SERVERNAME", "PLATFORM", "VERSION", "RELEASE",
            "LEVEL",      "SUBLEVEL"
        );

        my @status = &runTabdelDsmadmc(
"select server_name,platform,version,release,level,sublevel from status"
        );

        if ( !$LastErrorcode ) {

            my @values = split( /\t/, $status[0] );
            my $i = 0;

            foreach (@filedNames) {
                $TSMSeverStatus{$_} = $values[$i];
                $i++;
            }

        }
        else {

            # delete hash
            for ( keys %TSMSeverStatus ) {
                delete $TSMSeverStatus{$_};
            }

            $TSMSeverStatus{SERVERNAME} =
              &colorString( '!NOSERVER!', 'BOLD RED' );

        }
    }

}

#######################################################################################################################
# updatePrompt
#######################################################################################################################
sub updatePrompt() {

    &getTSMStatus();

    $CurrentPrompt = $Settings{PROMPT};

    for ( keys %TSMSeverStatus ) {
        $CurrentPrompt =~ s/$_/$TSMSeverStatus{$_}/g;
    }

}

#######################################################################################################################
# commandInjector
#######################################################################################################################
sub commandRegexp( $$$$ ) {

    my $finalRegexp     = '^\s*(';
    my $firstMinLenght  = ( $_[1] ne '' ) ? 2 : 3;
    $firstMinLenght     = $_[2] if ( defined ( $_[2] ) ); # override if 
    
    my $secondMinLenght = 3;
    $secondMinLenght    = $_[3] if ( defined ( $_[3] ) && $_[3] > 3 ); # override if 
           
    # first command 
    for ( my $string1 = $_[0]; length($string1) >= $firstMinLenght; $string1 = substr( $string1, 0, ( length($string1) - 1 ) ) )
    {
        $finalRegexp .= length($string1) > $firstMinLenght ? $string1 . '|' : $string1 . ')';
    }

    if ( $_[1] ne '' ) {

        $finalRegexp .= '\s+(';

        for ( my $string2 = $_[1]; length( $string2 ) >= $secondMinLenght; $string2 = substr( $string2, 0, ( length($string2) - 1 ) ) )
	{
            $finalRegexp .= length($string2) > $secondMinLenght ? $string2 . '|' : $string2 . ')';
        }

    }

    # 10 extra parameters
    $finalRegexp .= '[^\w]\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)';

    #print "[".$finalRegexp."]\n";
    #print uc( substr( $_[0], 0, $firstMinLenght ) ).substr( $_[0], $firstMinLenght )." ".uc( substr( $_[1], 0, $secondMinLenght ) ).substr( $_[1], $secondMinLenght )."\n";

    return $finalRegexp;

}

#######################################################################################################################
# grepIt
#######################################################################################################################
sub grepIt ( @ ) {

    my @return = @_;

    if (   defined( $ParameterRegExpValues{GREP} ) && $ParameterRegExpValues{GREP} ne "" && !$Settings{'DISABLEGREP'} )
    {
	foreach ( split( '&ANDGREP&', $ParameterRegExpValues{GREP} ) ) {
	    my $pattern = $_;
	    
	    $pattern =~ s/&ORGREP&/\|/g;
	    
            @return = grep( /($pattern)/i, @return );    ## Grep
	    
	     my @return2;
	    foreach ( @return ) {
		push ( @return2, &colorizeLineI( $_, '('.$pattern.')', $Settings{GREPCOLOR} ));
	    }
	    @return = @return2;
	}
    }

    if ( defined( $ParameterRegExpValues{INVGREP} ) && $ParameterRegExpValues{INVGREP} ne "" && !$Settings{'DISABLEGREP'} )
    {
	foreach ( split( '&ANDGREP&', $ParameterRegExpValues{INVGREP} ) ) {
	    my $pattern = $_;
            @return = grep( !/$pattern/i, @return );      ## INVGrep
	}
    }


    return @return;
}

sub deleteColumn( $@ ) {

    my $column = $_[0] if ( defined( $_[0] ) );
    splice( @_, 0, 1 );

    my @return;

    foreach ( @_ ) {

      my $c       = 0;
      my $newline = "";

      foreach ( split ( /\t/, $_ ) ) {
        $newline .= $_."\t" if ( $c++ != $column );
      }
      push ( @return, $newline );

    }

    return @return;

}

sub reach ( $ ) {

    &msg ( '0050I', $_[0] );

    if ( $OS_win )
    {
        system( "cmd /c start $_[0]" );
    }
    elsif ( $Settings{OS} eq "darwin" ) {
    	system( "open $_[0]" );
    }
    elsif ( $Settings{OS} eq "linux" )
    {
        system( "gnome-open $_[0]" );
    }
    else {
    	&msg ( '0033E');
    }

}

sub byteFormatter( $$ ) {

    my $bytes = $_[0];
    my $unit  = $_[1];

    my @units = ( 'B', 'KB', 'MB', 'GB', 'TB', 'PT');

    my $return;

    my $switch = 0;
    foreach ( @units ) {

        # find the first match
        if ( !$switch && $_ ne $unit ) {
          next;
        }
        else {
          $switch = 1;
        }

        if ( $bytes <= 1024 ) {
          $return = int( $bytes ).' '.$_;
          last;
        }

        $bytes = int( ( $bytes / 1024 ) + .5 );
    }

    return $return;

}

sub timeFormatter( $$ ) {

    my $time  = $_[0];
    my $unit  = $_[1];

    my @units = ( 's', 'M', 'H', 'D' );

    my $return;

    my $switch = 0;
    foreach ( @units ) {

        # find the first match
        if ( !$switch && $_ ne $unit ) {
          next;
        }
        else {
          $switch = 1;
        }

        my $current;

        if ( $_  eq 'H' ) {
            $current = 24;
        }
        elsif ( $_  eq 'D' ) {
          $return = $time.' '.$_;
          last;
        }
        else {
            $current = 60;
        }

        if ( $time <= $current  ) {
          $return = $time.' '.$_;
          last;
        }

        $time = int( ( $time / $current ) + .5 );
    }

    return $return;

}

## Global highlighter by _flex.
sub globalHighlighter ( $ ) {

    my $printableField = $_[0];

    foreach my $regexp ( keys %GlobalHighlighter ) {
	
	$printableField = &colorizeLine( $printableField, $regexp, $GlobalHighlighter{$regexp});

    }

    return $printableField;

}

sub colorizeLine ( $$$ ) {

    my $line   = $_[0];
    my $regexp = $_[1];
    my $color  = $_[2];

    # collect, save and convert
    my @save;
    my $i = 0;

    # hide ()
    $line =~ s/\(/{{/g;
    $line =~ s/\)/}}/g;

    while ( $line =~ m/$regexp/ ) {

	my $pattern = $1;
	my $coloredString = &colorString( $pattern, $color );

	 # find the previous color
	my $previousColor = "";

#print "LINE: $line".&colorLength($line)."\n";
#print "PATT: $pattern".&colorLength($pattern)."\n";

	# fix the regexp path with '\' and the escape sec \[
	$pattern =~ s/\\/\\\\/g;
	$pattern =~ s/\[/\\\[/g;

	if ( $line =~ m/(\e\[\d+;*\d*m)([^\e]+|\e(?!\[\d+;*\d*m))*$pattern/ )
	{
	    $previousColor = $1;
	}

	$line =~ s/$pattern/COLORIZE\[$i\]/;
	$save[$i] = $coloredString.$previousColor;

	$i++;

    }

    # restore everything
    while ( $line =~ m/COLORIZE\[(\d+)\]/ ) {

	my $index=$1;

	my $coloredString = $save[$index];
	
	# change the reset
#	my $justcolor = &colorString( "", $color );
#	$justcolor =~ s/\e\[0m//;
#	$coloredString =~ s/\e\[0m(.+)/$justcolor$1/g; 
	
	$line =~ s/COLORIZE\[$index\]/$coloredString/;

    }
	
    # unhide ()	
    $line =~ s/{{/\(/g;
    $line =~ s/}}/\)/g;			    
	
    return( $line );
     
}

sub colorizeLineI ( $$$ ) {

    my $line   = $_[0];
    my $regexp = $_[1];
    my $color  = $_[2];

    # collect, save and convert
    my @save;
    my $i = 0;

    while ( $line =~ m/$regexp/i ) {

	my $pattern = $1;
	my $coloredString = &colorString( $pattern, $color );

	 # find the previous color
	my $previousColor = "";

	if ( $line =~ m/(\e\[\d+;*\d*m)([^\e]+|\e(?!\[\d+;*\d*m))*($pattern)/ )
	{
	    $previousColor = $1;
	}
	
	$line =~ s/$pattern/COLORIZE\[$i\]/;
	$save[$i] = $coloredString.$previousColor;

	$i++;

    }

    # restore everything
    while ( $line =~ m/COLORIZE\[(\d+)\]/ ) {

	my $coloredString = $save[$1];
	$line =~ s/COLORIZE\[$1\]/$coloredString/;

    }
    
    return( $line );
 
}

sub printerGrepHighlighter ( $$$ ) {

    my $printableField = $_[0];
    my $regexp         = $_[1];
    my $color          = $_[2];

    # collect, save and convert
    my @save;
    my $i = 0;

    while ( $printableField =~ m/($regexp)/ ) {

        my $coloredString = &colorString( $1, $color );

        # find the previous color
        my $previousColor = "";
        if ( m/(\e\[\d+;\d+m).*($regexp)/ )
        {
            $previousColor = $1;
        }

        $printableField =~ s/$regexp/COLORIZE\[$i\]/;
        $save[$i] = $coloredString.$previousColor;

        $i++;

    }

    # restore everything
    while ( $printableField =~ m/COLORIZE\[(\d+)\]/ ) {

        my $coloredString = $save[$1];
        $printableField =~ s/COLORIZE\[$1\]/$coloredString/;

    }

    return $printableField;

}

sub sigInt () {
	$SIG{INT} = \&sigInt;
	&saveHistory;
	#warn "\n\aMi legyen??? Kilépjünk? Itt kellene elmenteni a historyt.\n";
        ReadMode('normal');
	exit 2;
}

sub saveHistory() {
            if ( !$OS_win ) {
                local $, = "\n";
                chomp(@History);
                if ( $#History > 256 ) { @History = splice( @History, -256 ); }
                if ( !-d dirname($Settings{HISTORYFILE}) ) {
                    mkpath( dirname($Settings{HISTORYFILE}) ) or die;
                }
                open my $HISTORY, ">", $Settings{HISTORYFILE} or die;
                print $HISTORY @History;
                close $HISTORY or die;
            }

}

sub updateTerminalSettings
{
    if ($OS_win)
    {

        # MS Windows environments
        my $CONSOLE = new Win32::Console;
        (
           $Settings{TERMINALCOLS},      $Settings{TERMINALROWS},
           $Settings{TERMINALCURSORCOL}, $Settings{TERMINALCURSORROW}
        ) = $CONSOLE->Info();
    }
    else
    {

        # UNIX like environments
        (
           $Settings{TERMINALCOLS},      $Settings{TERMINALROWS},
           $Settings{TERMINALCURSORCOL}, $Settings{TERMINALCURSORROW}
        ) = GetTerminalSize();
    }
    &msg("0017E") if ( $Settings{TERMINALCOLS} < 80 );
    # &msg( "0010D", $Settings{TERMINALCOLS}, $Settings{TERMINALROWS} );
}

sub colorHTMLtag()
{
    my $string = $_[0];
    my $color  = $_[1];

    if ( !$ParameterRegExpValues{NOCOLOR} && $color ne "" )
    {
        return "<FONT COLOR=\"$color\">" . $string . "</FONT>";
    }
    else
    {
        return $string;
    }
}

sub setServer($)
{

    &msg( "0004D", "setServer" );
    if (    !defined( $_[0] )
         || $_[0] =~ m/default$|defaul$|defau$|defa$|def$/i
         || $_[0] eq "" )
    {
        $Settings{SERVER} = $Settings{DEFAULTSERVER};
    }
    else
    {
        my $server = uc( $_[0] );
        if ($OS_win)
        {
            if ( $_[0] =~ m/(\S*)\/(\S*)@(\S*):(\d*)/i )
            {
                $Settings{'INLINE[TSMUSERNAME]'} = $1;
                $Settings{'INLINE[TSMPASSWORD]'} = $2;
                $Settings{'INLINE[TSMSERVER]'}   = $3;
                $Settings{'INLINE[TSMPORT]'}     = $4;
                $Settings{'SERVER'}              = "INLINE";
            }
            else
            {
                $Settings{SERVER} = $server;
            }
        }
        else
        {
            if ( $_[0] =~ m/(\S*)\/(\S*)@(\S*)/i )
            {
                $Settings{'INLINE[TSMUSERNAME]'} = $1;
                $Settings{'INLINE[TSMPASSWORD]'} = $2;
                $Settings{'INLINE[TSMSERVER]'}   = $3;
                $Settings{'SERVER'}              = "INLINE";
                return 0;
            }
            else
            {
                $Settings{SERVER} = $server;
            }

        }
    }
    my $TSMUserName = $Settings{SERVER} . "[TSMUSERNAME]";
    my $TSMPassword = $Settings{SERVER} . "[TSMPASSWORD]";
    my $TSMServer   = $Settings{SERVER} . "[TSMSERVER]";
    my $TSMPort     = $Settings{SERVER} . "[TSMPORT]" if ( $OS_win);

    if (    !defined( $Settings{$TSMServer} )
         || !defined( $Settings{$TSMUserName} )
         || !defined( $Settings{$TSMPassword} ) )
    {
        &msg( "0015E", "$Settings{SERVER}" );
        $Settings{SERVER} = $Settings{DEFAULTSERVER};
        $TSMUserName      = $Settings{SERVER} . "[TSMUSERNAME]";
        $TSMPassword      = $Settings{SERVER} . "[TSMPASSWORD]";
        $TSMServer        = $Settings{SERVER} . "[TSMSERVER]";
        $TSMPort          = $Settings{SERVER} . "[TSMPORT]" if ( $OS_win);
    }
    &msg( "0009D", "$TSMUserName", "$Settings{$TSMUserName}" );
    &msg( "0009D", "$TSMPassword", "$Settings{$TSMPassword}" );
    &msg( "0009D", "$TSMServer",   "$Settings{$TSMServer}" );
    &msg( "0009D", "$TSMPort",     "$Settings{$TSMPort}" ) if ( $OS_win);
    if ( $Settings{SERVER} eq "" )
    {
        &msg( "0014I", "DEFAULT" );
    }
    else
    {
        &msg( "0014I", "$Settings{SERVER}" );
    }
    &msg( "0005D", "setServer", 0 );
    return 0;

}

sub checkPassword ()
{
    if ( !defined( $_[0] ) )
    {
        &msg( "0001E", "checkPassword" );
        return 1;
    }
    my $configfileOption = $_[0];
    open( my $CONFIGFILE, "<$configfileOption" )
      or die "File ($configfileOption) open error: $!";
    my @fileContent = <$CONFIGFILE>;
    close($CONFIGFILE);

    my @codedContent;
    my $changed = 0;
    foreach (@fileContent)
    {
        if (m/TSMPASSWORD/)
        {

            my ( $hash_key, $hash_value ) = split( /=/, $_, 2 );
            $hash_key   =~ s/^\s*|\s*$//g;
            $hash_value =~ s/^\s*|\s*$//g;
            if ( $hash_value =~ m/^XOR{/i ) { push( @codedContent, $_ ); next; }
            my $passwordLength = length($hash_value);
            my $cipher         = substr( $cipherKey, 0, $passwordLength );
            my $xor            = $hash_value ^ $cipher;
            my $base64	       = MIME::Base64::encode($xor,"");
            push( @codedContent, "$hash_key = XOR{$base64}\n" );
            $changed = 1;
        }
        else
        {
            push( @codedContent, $_ );
        }
    }
    if ($changed)
    {
        open( my $CONFIGFILE, ">$configfileOption" )
          or die "File ($configfileOption) open error: $!";
        print $CONFIGFILE @codedContent;
        close($CONFIGFILE) or die "File ($configfileOption) close error: $!";
    }
}

sub getPassword ()
{
    &msg( "0004D", "getPassword" );
    if ( !defined( $_[0] ) )
    {
        &msg( "0001E", "getPassword" );
        return 1;
    }

    my $password = $_[0];

    if ( $password !~ m/^XOR{/ )
    {
        &msg("0016W");
        return $password;
    }
    $password =~ s/^XOR{//;
    $password =~ s/}$//;
    $password       = MIME::Base64::decode($password);
    my $passwordLength = length($password);
    my $cipher         = substr( $cipherKey, 0, $passwordLength );
    my $xor            = $password ^ $cipher;
    &msg( "0005D", "getPassword", 0 );
    return $xor;

}

sub addLineNumbers(@)
{
    &msg( "0004D", "addLineNumbers" );
    if ( !defined(@_) )
    {
        &msg( "0001E", "addLineNumbers" );
        return 1;
    }
    my @array = @_;
    my $i     = 0;
    foreach (@array)
    {
        $array[$i] = ( $i + 1 ) . "\t$array[$i]";
        $i++;
    }
    &msg( "0005D", "addLineNumbers", 0 );
    @LastResult = @array;
    return @array;
}

sub checkDefaults()
{
    &msg( "0004D", "checkDefaults" );

    if ( !defined( $Settings{DEFAULTSERVER} ) )
    {
        &msg( "0021E", "DEFAULTSERVER" );
        exit 1;
    }

    #	$Settings{DEFAULTCOLOR}   = 'GREEN' if (! defined ($Settings{DEFAULTCOLOR})) ;
    $Settings{HEADERCOLOR} = 'WHITE' if ( !defined( $Settings{HEADERCOLOR} ) );
    $Settings{HIGHLIGHTCOLOR} = 'RED'
      if ( !defined( $Settings{HIGHLIGHTCOLOR} ) );
    $Settings{AUTOCONNECT} = 1 if ( !defined( $Settings{AUTOCONNECT} ) );

    if ( !defined( $Settings{EDITOR} ) )
    {
        $Settings{EDITOR} = $OS_win ? "notepad" : "vi";

    }

    if ( !defined( $Settings{TERMINAL} ) )
    {
        $Settings{TERMINAL} = $OS_win ? "cmd" : "xterm";
    }

    if ( -r $Settings{HISTORYFILE} )
    {
        open my $HISTORY, "<", $Settings{HISTORYFILE} or die;
        @History = <$HISTORY>;
        close $HISTORY or die;
        chomp(@History);
        $HistoryPointer = $#History + 1;
    }
    else { $History[0] = ""; $HistoryPointer = $#History + 1; }

    &msg( "0005D", "checkDefaults", 0 );
}

sub readCommand()
{
    if ($OS_win)
    {
        return <STDIN>;
    }
    else
    {
        ReadMode("cbreak");
        my $input = "";
        my @chars;
        my $charPointer = 00;
        while ( push( @chars, ord( ReadKey(0) ) ) )
        {
            if ( $chars[-1] == 65 && $chars[-2] == 91 && $chars[-3] == 27 )
            {    # UP
                next if ( $HistoryPointer <= 0 );
                $HistoryPointer--;
                $input = $History[$HistoryPointer];
                print "\e[2K\r" . "$CurrentPrompt" . "$input";
                $charPointer = length($input);
                #open my $DEBUG, ">>", "debug.txt";
                #print $DEBUG "length: " . length($input) . ", charPointer: $charPointer\n";
                #close($DEBUG);

            }
            elsif ( $chars[-1] == 66 && $chars[-2] == 91 && $chars[-3] == 27 )
            {    # DOWN
                next if ( $HistoryPointer > ( @History - 1 ) );
                $input = "";
                $HistoryPointer++;
                $input = $History[$HistoryPointer]
                  if ( defined $History[$HistoryPointer] );
                print "\e[2K\r" . "$CurrentPrompt" . "$input";
                $charPointer = length($input);
                #open my $DEBUG, ">>", "debug.txt";
                #print $DEBUG "length: " . length($input) . ", charPointer: $charPointer\n";
                #close($DEBUG);

            }
            elsif ( $chars[-1] == 68 && $chars[-2] == 91 && $chars[-3] == 27 )
            {    # LEFT
                next if ( $charPointer <= 0 );
                print "\e[D";
                $charPointer--;
                #open my $DEBUG, ">>", "debug.txt";
                #print $DEBUG "length: " . length($input) . ", charPointer: $charPointer\n";
                #close($DEBUG);

            }
            elsif ( $chars[-1] == 67 && $chars[-2] == 91 && $chars[-3] == 27 )
            {    # RIGHT
                next if ( $charPointer >= length($input) );
                print "\e[C";
                $charPointer++;
                #open my $DEBUG, ">>", "debug.txt";
                #print $DEBUG "length: " . length($input) . ", charPointer: $charPointer\n";
                #close($DEBUG);

            }

            elsif ( $chars[-1] == 127 )
            {    # BACKSPACE
                next if ( $charPointer <= 0 );
                print "\e[D \e[D";
                $charPointer--;
                #$input = substr( $input, 0, $charPointer );
	                substr( $input, $charPointer, 1, "" );
                print "\e[s\e[2K\r" . "$CurrentPrompt" . "$input\e[u";

                #open my $DEBUG, ">>", "debug.txt";
                #print $DEBUG "length: " . length($input) . ", charPointer: $charPointer\n";
                #close($DEBUG);
            }
            elsif ( $chars[-1] == 80 && $chars[-2] == 79 && $chars[-3] == 27 )
            {    # F1
                print "\nStarting help for $input...\n";
		my $command = $input;
                    $HistoryPointer = @History;
                    if ($command ne $History[$HistoryPointer - 1] ) {
                        push( @History, $command );
                    }
                    $HistoryPointer = @History;
                    $input          = "";
                    ReadMode('normal');
                    #open my $DEBUG, ">>", "debug.txt";
                    #print $DEBUG "length: " . length($input) . ", charPointer: $charPointer\n";
                    #close($DEBUG);
                    print "\n";
                    return "help ".$command;
            }
            elsif ( $chars[-1] == 4 )
            {    # CTRL+D
                if ( $input eq "" )
                {
                    ReadMode('normal');
                    print "\n";
                    return "quit";
                }
            }
	    elsif ( $chars[-1] == 126 && $chars[-2] == 54 && $chars[-3] == 91 && $chars[-4] == 27 )
            {   # PGDOWN
		# print "PGDOWN\n";
            }
	    elsif ( $chars[-1] == 126 && $chars[-2] == 53 && $chars[-3] == 91 && $chars[-4] == 27 )
            {   # PGUP
		# print "PGUP\n";
            }
	    elsif ( $chars[-1] == 126 && $chars[-2] == 52 && $chars[-3] == 91 && $chars[-4] == 27 )
            {   # INSERT
		# print "INSERT\n";
            }	    
            elsif (    $chars[-1] == 126
                    && $chars[-2] == 51
                    && $chars[-3] == 91
                    && $chars[-4] == 27 )
            {    # DELETE
                substr( $input, $charPointer, 1, "" );
                print "\e[s\e[2K\r" . "$CurrentPrompt" . "$input\e[u";
            }
            elsif ( $chars[-1] == 1 )
            {    # CTRL-A
                print "CTRL-A\n";
            }
            elsif ( $chars[-1] == 91 && $chars[-2] == 27 )
            {    # OMITT
            }
            elsif ( $chars[-1] == 79 && $chars[-2] == 27 )
            {    # OMITT
            }
            elsif ( $chars[-1] == 51 && $chars[-2] == 91 && $chars[-3] == 27 )
            {    # OMITT
            }
            elsif ( $chars[-1] == 27 )
            {    # ESC
            
                #if ( $input ne "" )
                #{
                #    $input = "";
                #    open DEBUG, ">>", "debug.txt";
                #    print DEBUG "ESClength: " . length($input) . ", charPointer: $charPointer\n";
                #    close(DEBUG);
                #    print "\e[2K\r" . "$Settings{PROMPT}" . "$input";
                #}
            
            }
            elsif ( $chars[-1] == 10 )
            {    # ENTER

                if ( $input =~ m/\w/ )
                {
                    my $command = $input;
                    $HistoryPointer = @History;
                    if ($command ne $History[$HistoryPointer - 1] ) {
                        push( @History, $command );
                    }
                    $HistoryPointer = @History;
                    $input          = "";
                    ReadMode('normal');
                    #open my $DEBUG, ">>", "debug.txt";
                    #print $DEBUG "length: " . length($input) . ", charPointer: $charPointer\n";
                    #close($DEBUG);
                    print "\n";
                    return $command;
                }
                else
                {
                    print "\n" . "$CurrentPrompt";
                }
            }
            else
            {
                if ( $charPointer <= length($input) )
                {
                    substr( $input, $charPointer, 1, chr( $chars[-1] ) );
                    $charPointer++;
                }
                else
                {
                    $input .= chr( $chars[-1] );
                }
                print chr( $chars[-1] );
                #open my $DEBUG, ">>", "debug.txt";
                #print $DEBUG "length: " . length($input) . ", charPointer: $charPointer\n";
                #close($DEBUG);
            }
        }

        ReadMode('normal');
    }

}

1;
