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

# ---

my $extraParameters;           #

#####################
# Run a TSM command
#####################
sub runTabdelDsmadmc ( $$ ) {

    $extraParameters = "-dataonly=yes -tabdel";

    &Dsmadmc( $_[0], $_[1] );

}

sub runDsmadmc ( $ ) {

    if ( ! $ParameterRegExpValues{TABMODE} ) {
	$extraParameters = ( $_[0] =~ m/(\s*q\w*\s+sta\w*|f=d)/ || $ParameterRegExpValues{LISTMODE} ) ? "-DISPLaymode=LISt" : "";
    }
    else {
	$extraParameters = "-DISPLaymode=TABle";
    }

    &Dsmadmc( $_[0] );

}

sub Dsmadmc ( $$ ) {

    # return if empty string
    return if ( $_[0] eq "" );

    my @return;

    # reset last error...
    $LastErrorcode    = 0;
    $LastErrorMessage = "";

    $extraParameters = "" if ( ! defined( $extraParameters ) );

#Debug
#print &colorString(  &textLine( "DEBUG: QUERY: [$_[0]] + extra:[$extraParameters]. ", "-" ), "bold red" );
    &msg( "0006D", "$_[0]", "$extraParameters" );
    if ( defined( $Settings{'DEBUG'} ) && $Settings{'DEBUG'} ) {
            &universalTextPrinter( "TADM0006D\tCOMMAND DETAILS[CYAN]", "         \t".$_[0] );
    }

    print "<->\r" if ( !defined( $Settings{QUIET} ) );

    my $TSMUserName     = $Settings{SERVER}."[TSMUSERNAME]";
    my $TSMPassword     = $Settings{SERVER}."[TSMPASSWORD]";
    my $TSMServer       = $Settings{SERVER}."[TSMSERVER]";
    my $TSMPort         = $Settings{SERVER}."[TSMPORT]";
    my $decodedPassword = &getPassword( $Settings{$TSMPassword} );

    #
    my $command = $_[0];
    $command =~ s /[^\\]"/\\"/g;

    my $serverCommandRouting = '';
    $serverCommandRouting .= $ParameterRegExpValues{SERVERCOMMANDROUTING1} if ( defined $ParameterRegExpValues{SERVERCOMMANDROUTING1} );
    $serverCommandRouting .= $ParameterRegExpValues{SERVERCOMMANDROUTING2} if ( defined $ParameterRegExpValues{SERVERCOMMANDROUTING2} );
    $serverCommandRouting = '('.$serverCommandRouting.') ' if ( $serverCommandRouting ne '' );

    if ( $OS_win ) {
        $ENV{"DSM_DIR"} = $Settings{DSM_DIR}
          if ( defined( $Settings{DSM_DIR} ) );
        $ENV{"DSM_LOG"} = $Settings{DSM_LOG}
          if ( defined( $Settings{DSM_LOG} ) );
        $ENV{"DSM_CONFIG"} = $Settings{DSM_CONFIG}
          if ( defined( $Settings{DSM_CONFIG} ) );
        open( PIPE,
                '"'
              . $Settings{DSMADMC} . '"'
              . " -id=$Settings{$TSMUserName} -password=$decodedPassword $extraParameters -tcpserveraddress=$Settings{$TSMServer} -tcpport=$Settings{$TSMPort} ".'"'.$serverCommandRouting.$_[0].'"'." |"
#              . " -id=$Settings{$TSMUserName} -password=$decodedPassword $extraParameters -tcpserveraddress=$Settings{$TSMServer} -tcpport=$Settings{$TSMPort} ".$_[0]." |"
        );
    }
    else {
        $ENV{"DSM_DIR"} = $Settings{DSM_DIR}
          if ( defined( $Settings{DSM_DIR} ) );
        $ENV{"DSM_LOG"} = $Settings{DSM_LOG}
          if ( defined( $Settings{DSM_LOG} ) );
        $ENV{"DSM_CONFIG"} = $Settings{DSM_CONFIG}
          if ( defined( $Settings{DSM_CONFIG} ) );
        open( PIPE, "$Settings{DSMADMC} -id=$Settings{$TSMUserName} -password=$decodedPassword $extraParameters -se=$Settings{$TSMServer} ".'"'.$serverCommandRouting.$_[0].'"'." |" );
#        open( PIPE, "$Settings{DSMADMC} -id=$Settings{$TSMUserName} -password=$decodedPassword $extraParameters -se=$Settings{$TSMServer} ".$_[0]." |" );
    }

    while ( <PIPE> ) {
        chomp;

# die "Session rejected: TCP\/IP connection failure" if ( m/^ANS1017E Session rejected: TCP\/IP connection failure/ );
# die "Unable to establish session with server" if ( m/^ANS8023E Unable to establish session with server/ );
        next if (m/$ExcludeList/);    # discard exluded lines

        # store the returncode
        if (m/^ANS8002I Highest return code was (\d+)/) {
            $LastErrorMessage = $1;
            next;
        }

        # skip this annoying message
        if (m/^(ANS2036W.*)/) {
            &msg ( '0099E', $1 );
            next;
        }

        push( @return, "$_" ) if ($_);
    }
    close PIPE;

    $LastErrorcode = $? >> 8;         # save the errorcode

    &msg( "0008D", $LastErrorcode );
    &msg( "0007D", $#return+1 );

    if ( ! $LastErrorcode ) {

        # 0
        if ( defined( $_[1] ) && $_[1] ne "" && !$ParameterRegExpValues{NOHISTORY} ) {
            # save history file
            if ( $TSMSeverStatus{SERVERNAME} !~ m/\!NOSERVER\!/ ) {
              my $mode = ( $CommandMode eq 'BATCH' ) ? 'B' : '';
              &saveArray2File( "$Settings{ARCHIVEDIRECTORY}/$_[1]", $TSMSeverStatus{SERVERNAME}.'_'.$_[1].'_'.&createTimestamp().$mode.'.txt', @return );
            }
        }

        # grep and invgrep
        #@return = &grepIt ( @return );
	
    }
    else {

        # >0 error
        my @coloredError;
        
        foreach ( @return ) {
            push ( @coloredError, &colorString( $_, "BOLD RED") );
        }

        @return = @coloredError;

    }
    
    &setTitle() if ( $OS_win );

    return @return;
}

sub startConsole ()
{
    &msg( "0004D", "startConsole" );

    if ($OS_win)
    {
	system( "cmd /c start perl $Dirname/tsmadm.pl --config \"$Settings{CONFIGFILE}\" --server $Settings{SERVER} -console " );
    }
    else
    {
        system( "$Settings{TERMINAL} -e $Dirname/tsmadm.pl --config $Settings{CONFIGFILE} --server $Settings{SERVER} -console &" );
    }

    &msg( "0005D", "startConsole", 0 );
    return 0;
}

sub startDsmadmc ( $ )
{
    &msg( "0004D", "startDsmadmc" );

    my $TSMUserName     = $Settings{SERVER} . "[TSMUSERNAME]";
    my $TSMPassword     = $Settings{SERVER} . "[TSMPASSWORD]";
    my $TSMServer       = $Settings{SERVER} . "[TSMSERVER]";
    my $TSMPort         = $Settings{SERVER} . "[TSMPORT]";
    my $decodedPassword = &getPassword( $Settings{$TSMPassword} );

    my $connectString = " ";
    $connectString = " -id=$Settings{$TSMUserName} -password=$decodedPassword " if ( defined ( $_[0] ) && $_[0] eq 'AUTOLOGIN' );

    if ($OS_win)
    {
        $connectString .= " -tcpserveraddress=$Settings{$TSMServer} -tcpport=$Settings{$TSMPort}";
    }
    else
    {
        $connectString .= " -se=$Settings{$TSMServer}";
    }

    if ( $OS_win )
    {
        $ENV{"DSM_DIR"} = $Settings{DSM_DIR}       if ( defined( $Settings{DSM_DIR} ) );
        $ENV{"DSM_LOG"} = $Settings{DSM_LOG}       if ( defined( $Settings{DSM_LOG} ) );
        $ENV{"DSM_CONFIG"} = $Settings{DSM_CONFIG} if ( defined( $Settings{DSM_CONFIG} ) );
        system(   "cmd /c start " . '"'
                . "DSMADMC from tsmadm.pl" . '" ' . '"'
                . "$Settings{DSMADMC}" . '"'
                . $connectString );
	
	&setTitle();
	
    }
    else
    {
        $ENV{"DSM_DIR"} = $Settings{DSM_DIR}       if ( defined( $Settings{DSM_DIR} ) );
        $ENV{"DSM_LOG"} = $Settings{DSM_LOG}       if ( defined( $Settings{DSM_LOG} ) );
        $ENV{"DSM_CONFIG"} = $Settings{DSM_CONFIG} if ( defined( $Settings{DSM_CONFIG} ) );
        system("$Settings{TERMINAL} -e $Settings{DSMADMC} $connectString &");
    }

    &msg( "0005D", "startDsmadmc", 0 );

    return 0;
}

    our $pid;

sub consoleHighlighter()
{
    my $TSMUserName     = $Settings{SERVER} . "[TSMUSERNAME]";
    my $TSMPassword     = $Settings{SERVER} . "[TSMPASSWORD]";
    my $TSMServer       = $Settings{SERVER} . "[TSMSERVER]";
    my $TSMPort         = $Settings{SERVER} . "[TSMPORT]";
    my $decodedPassword = &getPassword( $Settings{$TSMPassword} );
    my $connectString   = " -console -id=$Settings{$TSMUserName} -password=$decodedPassword -NOConfirm ";

    if ( $OS_win )
    {
        $connectString .= " -tcpserveraddress=$Settings{$TSMServer} -tcpport=$Settings{$TSMPort}";
    }
    else
    {
        $connectString .= " -se=$Settings{$TSMServer}";
    }

    $SIG{INT} = \&sigIntConsole;
    
    if ($OS_win)
    {
        $ENV{"DSM_DIR"} = $Settings{DSM_DIR}       if ( defined( $Settings{DSM_DIR} ) );
        $ENV{"DSM_LOG"} = $Settings{DSM_LOG}       if ( defined( $Settings{DSM_LOG} ) );
        $ENV{"DSM_CONFIG"} = $Settings{DSM_CONFIG} if ( defined( $Settings{DSM_CONFIG} ) );
        $pid = open( PIPE, '"' . $Settings{DSMADMC} . '"' . $connectString . " |" );
    }
    else
    {
        $ENV{"DSM_DIR"} = $Settings{DSM_DIR}       if ( defined( $Settings{DSM_DIR} ) );
        $ENV{"DSM_LOG"} = $Settings{DSM_LOG}       if ( defined( $Settings{DSM_LOG} ) );
        $ENV{"DSM_CONFIG"} = $Settings{DSM_CONFIG} if ( defined( $Settings{DSM_CONFIG} ) );
        $pid = open( PIPE, "$Settings{DSMADMC}" . $connectString . " |" );
    }

    while ( <PIPE> )
    {
        if (m/ANR....E/) { print &colorString( $_, "BOLD RED" );    next; }
        if (m/ANR....W/) { print &colorString( $_, "BOLD YELLOW" ); next; }

        print &globalHighlighter( $_ );
    }
    close PIPE;

    # msg
    <STDIN>;

    exit;

}

sub sigIntConsole {
	
    print "a1 [$pid]\n";
	
    kill ( 9, $pid );
    #close PIPE;
	
    print "a2 [$pid]\n";
	
}

1;
