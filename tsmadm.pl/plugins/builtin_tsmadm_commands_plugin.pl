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

&msg( '0110D', 'Built-in commands' );

&msg( '0110D', 'SHow VERsion' );
$Commands{&commandRegexp( 'show', 'version' )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow VERsion Help!\n";
        print "--------\n";

        return 0; # Ok
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "Version{RIGHT}", $tsmadmplVersion );

    return 0; # matched

};
&defineAlias( 'ver', 'show version' );

&msg( '0110D', 'SHow LASterror' );
$Commands{&commandRegexp( 'show', 'lasterror' )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow LASterror Help!\n";
        print "--------\n";

        return 0; # Ok
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "Last Errorcode{RIGHT}", $LastErrorMessage );

    return 0; # matched

};
&defineAlias( 'last', 'show lasterror' );

&msg( '0110D', 'SHow ENVironment' );
$Commands{&commandRegexp( 'show', 'environment' )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow ENVironment Help!\n";
        print "--------\n";

        return 0; # Ok
    }

    my @printable;
    
    for my $key ( sort( keys %Settings ) ) {
        push( @printable, "$key\t=\t".&colorString( "[", "BOLD WHITE" ).&colorString( $Settings{$key}, "BOLD YELLOW" ).&colorString( "]", "BOLD WHITE" ) );
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "KEY[GREEN]\t\tVALUE", @printable );

    return 0; # matched

};

&msg( '0110D', 'SHow SERvers' );
$Commands{&commandRegexp( 'show', 'servers' )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow SERvers Help!\n";
        print "--------\n";

        return 0; # Ok
    }

    my @printable;

    for my $key ( sort( keys %Settings ) ) {
        push( @printable, "$1" ) if ( $key =~ m/(^.*)\[TSMSERVER\]/ );
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "Servers{RIGHT}", &grepIt ( @printable ) );

    return 0; # matched

};

&msg( '0110D', 'SHow COMmands' );
$Commands{&commandRegexp( 'show', 'commands' )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow COMmands Help!\n";
        print "--------\n";

        return 0; # Ok
    }

    my @printable;

    for my $key ( keys %Commands ) {
        
        if ( $key =~ m/\((\w+).*\((\w+)/ ) {
            push( @printable, "$1\t$2" );
        
        }
        else {        
            push( @printable, "$1" ) if ( $key =~ m/\((\w+).*/ );
        }
    }
    
    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tCommands{RIGHT}\t ", &addLineNumbers( sort ( @printable ) ) );

    return 0; # matched

};

&msg( '0110D', 'SHow RULer' );
$Commands{&commandRegexp( 'show', 'ruler' )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow RULer Help!\n";
        print "--------\n";

        return 0; # Ok
    }

    &showRuler();

    return 0; # matched

};
&defineAlias( 'ruler', 'show ruler' );

&msg( '0110D', 'RELoad' );
$Commands{&commandRegexp( 'reload', '' )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "REload Help!\n";
        print "--------\n";

        return 0; # Ok
    }

    &reLoadPlugins();

    return 0; # matched

};

&msg( '0110D', 'ALIas' );
$Commands{&commandRegexp( 'alias', '' )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print <<ALIASHELPEND;
alias [name=value]

With name=value specified, define name as an alias and assign it the value value. A trailing space in value causes the next word to be checked for alias substitution.

With name=value omitted, print the list of aliases in the form name=value on standard output.
ALIASHELPEND

        return 0;
    }

    if ( !defined $2 || $2 eq '' ) {
        
        my @printable;
        
        foreach my $key ( sort keys %Aliases ) { 
            push( @printable, "$key\t=\t".&colorString( "[", "BOLD WHITE" ).&colorString( $Aliases{$key}, "BOLD YELLOW" ).&colorString( "]", "BOLD WHITE" ) );
        }

        &setSimpleTXTOutput();
        &universalTextPrinter( "ALIAS\t\tCOMMAND", &grepIt ( @printable ) );

    }
    else {
        #my ( $alias, $command ) = split( /\s*=\s*/, $2 );
        my $parameter = $2." ".$3." ".$4." ".$5." ".$6." ".$7." ".$8." ".$9;
        if ( $parameter =~ m/\s*(.+)\s*=\s*(.+)\s*/ ) {
            my $alias   = $1;
            my $command = $2;
            
            $command =~ s/^\s+//;
            
            &defineAlias( $alias, $command ) if ( $alias  ne '' );
            delete $Aliases{$alias}          if ( ! defined( $command ) || $command eq '' ); # delete if empty
        }
    }

    return 0;

};

##################################################################

&msg( '0110D', 'SEt SERver' );
$Commands{&commandRegexp( 'set', 'server' )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SEt SERver Help!\n";
        print "--------\n";
        pod2usage(
            -input    => "plugins/builtin_commands.pl",
            -exitval  => 'NOEXIT',
            -verbose  => 99,
            -sections => [ "SETSERVER", "NAME" ]
        );
        return 0;
    }

    &setServer($3);

    &updatePrompt();

    return 0;

};
&defineAlias( 'server', 'set server' );

&msg( '0110D', 'CONsole' );
$Commands{&commandRegexp( 'console', '' )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "Console Help!\n";
        print "--------\n";
        pod2usage( -verbose => 3, -sections => "CONSOLE" );
        return 0;
    }
    &startConsole;
    return 0;

};

&msg( '0110D', 'Mount' );
$Commands{&commandRegexp( 'mount', '' )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "Console Help!\n";
        print "--------\n";
        pod2usage( -verbose => 3, -sections => "MOUNT" );
        return 0;
    }
    &startMount;
    return 0;

};

&msg( '0110D', 'DEBug' );
$Commands{&commandRegexp( 'debug', '' )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "DEBug Help!\n";
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

1;

__END__

=pod

=head SETSERVER

 SEt SERver C<KORNYEZET>

=head2 NAME

SEt SERver

=head1 SYNOPSIS

SEt SERver I<server név>

=head1 DESCRIPTION

Beállítja a TSM szerverhez történő csatlakozáshoz szükséges paramétereket


=head CONSOLE

=head1 NAME

CONsole


=head1 SYNOPSIS

CONsole

=head1 DESCRIPTION


Megjeleníti a dsmadmc konzol ablakát


