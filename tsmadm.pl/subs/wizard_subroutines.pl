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

### Init Answer hashs
my %answer;
my %question;

### setDefault: minden érték egy szubrutin, ami a hozzá tartozó elem default értékét állítja be
my %setDefault;

### checkDefault: ellenõrzi, hogy a bevitt érték ténylég helyes-e, szintén szubrutin minden érték.
my %checkDefault;

### Tartalmazza az alapértelemezett értékeket
my %default;

### Tartalmazza a leírásokat
my %description;

my @servers;

sub wizard ()
{

    &updateTerminalSettings;

    my $str;
    my @string;
    my $i = 0;

    print $^O;
    my $formatline = "@" . "|" x ( $Settings{TERMINALCOLS} - 2 );
    my $format = "format STDOUT =
$formatline
\$str
.";

    eval $format;
    print "\n\n\n\n\n\n";
    $string[0] = "   _/                                                _/              ";
    $string[1] = "_/_/_/_/    _/_/_/  _/_/_/  _/_/      _/_/_/    _/_/_/  _/_/_/  _/_/ ";
    $string[2] = " _/      _/_/      _/    _/    _/  _/    _/  _/    _/  _/    _/    _/";
    $string[3] = "_/          _/_/  _/    _/    _/  _/    _/  _/    _/  _/    _/    _/ ";
    $string[4] = " _/_/  _/_/_/    _/    _/    _/    _/_/_/    _/_/_/  _/    _/    _/  ";
    $string[5] = "                                                                     ";
    $string[6] = "Configuration Wizard";

    foreach (@string)
    {
        $str = $_;
        write;
    }
    print "Dear User,

You can see the tsmadm.pl wizard now which has started because you used the --wizard option or the program didn't find the configuration file(tsmadm.conf).  
    
You can quit from this wizard using the "quit" command anywhere or just simple press CTRL+C. 

Let's start!
        
";

### Questions
    %question = (
                DSM_DIR         => "Add meg a DSM_DIR erteket:",
                DSM_LOG         => "Add meg a DSM_LOG erteket:",
                DSM_CONFIG      => "Add meg a DSM_CONFIG erteket:",
                DEBUG           => "Szeretned DEBUG opcioval futtatni a programot?",
                MORE_TSM_SERVER => "\nWould you like to add other server options to the config file?",
                TSM_SERVER_NAME => "Please type TSM Server section name:",
                TSMSERVER       => "Szervernev (hosztnev vagy IP cim windows-on, szekcionev minden mas rendszeren):",
                TSMPORT         => "TCP port:",
                TSMUSERNAME     => "Felhasznalonev:",
                TSMPASSWORD     => "Jelszo:",
                DEFAULTSERVER   => "Melyik szerver legyen az alapertelmezett?",
    );

    $description{DSM_DIR} = "

DSM Directory

Please type your tsm installation directory, where we find dsmadmc program
If you would like to accept the default option, just press ENTER.
Every other directory, is also accepted..

";

    $description{DSM_LOG} = "

DSM LOG Directory

Please type your tsm log directory, where you want to ....
If you would like to accept the default option, just press ENTER.
Every other directory, is also accepted..

";

    $description{DSM_CONFIG} = "

DSM CONFIG file (a.k.a. dsm.opt)

Where can we find?

";

    $description{DEBUG} = "

DEBUG Mode

Would like to use DEBUG mode, by default?
Of course, you can turn on...

";

    $description{TSM_SERVER_NAME} = "

TSM Server Section name

Kesobb a szekcionevvel tudsz hivatkozni az egyes szerverekre:
A set server <szekcionev> parancs segitsegevel lehetoseged van tobb TSM szerver kezelesere, anelkul, hogy a programbol kilepnel.

";

    $description{TSMSERVER} = "

 - TSM Server address/name

   Itt add meg a TSM szervered nevet IP cimet, vagy ha nem windows-t hasznalsz,
   akkor a dsm.opt fajlban a szekcio nevet


";
    $description{TSMPORT} = "

 - TSM Server port

";
    $description{TSMUSERNAME} = "

 - TSM Server username

   Felhasznalonev, amivel a TSM szervert szeretned adminisztralni

";
    $description{TSMPASSWORD} = "

 - TSM Server password

   Jelszo, a korabban megadott felhasznalonevhez

";
    $description{DEFAULTSERVER} = "

Default server section

Megadhatod, hogy melyik szerver legyen az alapertelmezett, amikor a tsmadm.pl elindul. 

";

    $setDefault{'DEFAULTSERVER'} = sub () {
        $default{'DEFAULTSERVER'} = $servers[0];
    };

    $setDefault{'TSM_SERVER_NAME'} = sub () {
        my $postfix = $i ? "_$i" : '';
        $i++;
        $default{'TSM_SERVER_NAME'} = 'DEFAULT' . $postfix;

    };

    $setDefault{'TSMSERVER'} = sub () {
        $default{'TSMSERVER'} = '127.0.0.1';
    };

    $setDefault{'TSMPORT'} = sub () {
        $default{'TSMPORT'} = '1500';
    };
    $setDefault{'TSMUSERNAME'} = sub () {
        $default{'TSMUSERNAME'} = 'admin';
    };

    $setDefault{'TSMPASSWORD'} = sub () {
        $default{'TSMPASSWORD'} = 'admin';
    };

    $setDefault{'DSM_DIR'} = sub () {
        if ( defined $ENV{DSM_DIR} )
        {
            $default{DSM_DIR} = $ENV{DSM_DIR};
        }
        elsif ( $^O eq "darwin"
                && -d "/Library/Application Support/tivoli/tsm/client/ba/bin/" )
        {
            $default{DSM_DIR} = "/Library/Application Support/tivoli/tsm/client/ba/bin/";
        }
        elsif ( $^O eq "linux"
                && -d "/opt/tivoli/tsm/client/ba/bin/" )
        {
            $default{DSM_DIR} = "/opt/tivoli/tsm/client/ba/bin/";
        }
        elsif ( $^O eq "hpux"
                && -d "/opt/tivoli/tsm/client/ba/bin/" )
        {
            $default{DSM_DIR} = "/opt/tivoli/tsm/client/ba/bin/";
        }
        elsif ( $^O eq "aix"
                && -d "/usr/tivoli/tsm/client/ba/bin/" )
        {
            $default{DSM_DIR} = "/usr/tivoli/tsm/client/ba/bin/";
        }
        elsif ( $^O eq "MSWin32" && -d 'C:\Program Files\Tivoli\TSM\baclient' )
        {
            $default{DSM_DIR} = 'C:\Program Files\Tivoli\TSM\baclient';
        }
        elsif ( $^O eq "MSWin32" && -d 'D:\Program Files\Tivoli\TSM\baclient' )
        {
            $default{DSM_DIR} = 'D:\Program Files\Tivoli\TSM\baclient';
        }
        else
        {
            $default{DSM_DIR} = "";
        }
    };

    $setDefault{'DSM_LOG'} = sub () {
        if ( defined $ENV{DSM_LOG} )
        {
            $default{DSM_LOG} = $ENV{DSM_LOG};
        }
        elsif ( $^O eq "darwin"
                && -d "/Library/Application Support/tivoli/tsm/client/ba/bin/" )
        {
            $default{DSM_LOG} = "/Library/Application Support/tivoli/tsm/client/ba/bin/";
        }
        elsif ( $^O eq "aix"
                && -d "/usr/tivoli/tsm/client/ba/bin/" )
        {
            $default{DSM_LOG} = "/usr/tivoli/tsm/client/ba/bin/";
        }
        elsif ( $^O eq "linux"
                && -d "/opt/tivoli/tsm/client/ba/bin/" )
        {
            $default{DSM_LOG} = "/opt/tivoli/tsm/client/ba/bin/";
        }
        elsif ( $^O eq "hpux"
                && -d "/opt/tivoli/tsm/client/ba/bin/" )
        {
            $default{DSM_LOG} = "/opt/tivoli/tsm/client/ba/bin/";
        }
        elsif ( $^O eq "MSWin32" && -d 'C:\Program Files\Tivoli\TSM\baclient' )
        {
            $default{DSM_LOG} = 'C:\Program Files\Tivoli\TSM\baclient';
        }
        elsif ( $^O eq "MSWin32" && -d 'D:\Program Files\Tivoli\TSM\baclient' )
        {
            $default{DSM_LOG} = 'D:\Program Files\Tivoli\TSM\baclient';
        }
        else
        {
            $default{DSM_LOG} = "";
        }
    };

    $setDefault{'DSM_CONFIG'} = sub {
        if ( defined $ENV{DSM_CONFIG} )
        {
            $default{DSM_CONFIG} = $ENV{DSM_CONFIG};
        }
        elsif (    $^O eq "darwin"
                && -r "/Library/Preferences/Tivoli Storage Manager/dsm.opt"
                && -f "/Library/Preferences/Tivoli Storage Manager/dsm.opt" )
        {
            $default{DSM_CONFIG} = "/Library/Preferences/Tivoli Storage Manager/dsm.opt";
        }
        elsif ( $^O eq "linux"
                && -r "/opt/tivoli/tsm/client/ba/bin/dsm.opt"
                && -r "/opt/tivoli/tsm/client/ba/bin/dsm.opt")
        {
            $default{DSM_CONFIG} = "/opt/tivoli/tsm/client/ba/bin/dsm.opt";
        }
        elsif ( $^O eq "hpux"
                && -r "/opt/tivoli/tsm/client/ba/bin/dsm.opt"
                && -r "/opt/tivoli/tsm/client/ba/bin/dsm.opt")
        {
            $default{DSM_CONFIG} = "/opt/tivoli/tsm/client/ba/bin/dsm.opt";
        }
        elsif ( $^O eq "aix"
                && -r "/usr/tivoli/tsm/client/ba/bin/dsm.opt"
                && -r "/usr/tivoli/tsm/client/ba/bin/dsm.opt")
        {
            $default{DSM_CONFIG} = "/usr/tivoli/tsm/client/ba/bin/dsm.opt";
        }
        elsif (    $^O eq "MSWin32"
                && -r 'C:\Program Files\Tivoli\TSM\baclient\dsm.opt'
                && -f 'C:\Program Files\Tivoli\TSM\baclient\dsm.opt' )
        {
            $default{DSM_CONFIG} = 'C:\Program Files\Tivoli\TSM\baclient\dsm.opt';
        }
        elsif (    $^O eq "MSWin32"
                && -r 'D:\Program Files\Tivoli\TSM\baclient\dsm.opt'
                && -f 'D:\Program Files\Tivoli\TSM\baclient\dsm.opt' )
        {
            $default{DSM_CONFIG} = 'D:\Program Files\Tivoli\TSM\baclient\dsm.opt';
        }
        else
        {
            $default{DSM_CONFIG} = "";
        }
    };
    $setDefault{'DEBUG'} = sub {
        $default{DEBUG} = "false";

    };
    $setDefault{'MORE_TSM_SERVER'} = sub {
        $default{'MORE_TSM_SERVER'} = "no";
    };

    $checkDefault{'DEFAULTSERVER'} = sub {
        if ( $answer{'DEFAULTSERVER'} eq 'NA' )
        {
            print "Possible options: @servers\n";
            return 1;
        }
        else
        {
            my $isFound = 1;
            foreach (@servers)
            {
                $isFound = 0 if ( $answer{'DEFAULTSERVER'} eq $_ );
            }
            print "Possible options: @servers\n" if ($isFound);
            return $isFound;
        }
    };

    $checkDefault{'TSMSERVER'} = sub {
        if ( $answer{'TSMSERVER'} eq "" )
        {
            print "Please type chars, empty string not allowed!\n";
            return 1;
        }
        elsif ( $answer{'TSMSERVER'} eq 'NA' )
        {
            return 1;
        }
        else
        {
            return 0;
        }
    };
    $checkDefault{'TSMPORT'} = sub {
        if ( $answer{'TSMPORT'} !~ /[0-9]+/ && $answer{'TSMPORT'} ne 'NA' )
        {
            print "Please type decimals!\n";
            return 1;
        }
        elsif ( $answer{'TSMPORT'} ne 'NA' && ( $answer{'TSMPORT'} < 1 || $answer{'TSMPORT'} > 65532 )  )
        {
            print "Please type decimals, between 0 and 65532!\n";
            return 1;
        }
        elsif ( $answer{'TSMPORT'} eq 'NA' )
        {
            return 1;
        }
        else
        {
            return 0;
        }
    };
    $checkDefault{'TSMUSERNAME'} = sub {
        if ( $answer{'TSMUSERNAME'} eq "" )
        {
            print "Please type chars, empty string not allowed!\n";
            return 1;
        }
        elsif ( $answer{'TSMUSERNAME'} eq 'NA' )
        {
            return 1;
        }
        else
        {
            return 0;
        }
    };
    $checkDefault{'TSMPASSWORD'} = sub {

        if ( $answer{'TSMPASSWORD'} eq "" )
        {
            print "Please type chars, empty string not allowed!\n";
            return 1;
        }
        elsif ( $answer{'TSMPASSWORD'} eq 'NA' )
        {
            return 1;
        }
        else
        {
            return 0;
        }
    };

    $checkDefault{'TSM_SERVER_NAME'} = sub {
        if ( $answer{'TSM_SERVER_NAME'} eq "" )
        {
            print "Please type chars, empty string not allowed!\n";
            return 1;
        }
        elsif ( $answer{'TSM_SERVER_NAME'} eq 'NA' )
        {
            return 1;
        }
        else
        {
            return 0;
        }
    };
    $checkDefault{'DSM_CONFIG'} = sub {
        return 0
          if ( -r "$answer{'DSM_CONFIG'}" && -f "$answer{'DSM_CONFIG'}" );
        print "I think this is not a file or not readable!\n"
          if ( $answer{'DSM_CONFIG'} ne 'NA' );
        return 1;
    };
    $checkDefault{'DSM_DIR'} = sub {
        return 0
          if (    -d "$answer{'DSM_DIR'}"
               && -x "$answer{'DSM_DIR'}/dsmadmc" . ( $OS_win ? '.exe' : '' ) );
        print "I think this is not a directory or dsmadmc"
          . ( $OS_win ? '.exe' : '' )
          . " can not find!\n"
          if ( $answer{'DSM_DIR'} ne 'NA' );
        return 1;
    };
    $checkDefault{'DSM_LOG'} = sub {
        return 0 if ( -d "$answer{'DSM_LOG'}" );
        print "I think this is not a directory!\n"
          if ( $answer{'DSM_LOG'} ne 'NA' );
        return 1;
    };
    $checkDefault{'DEBUG'} = sub {
        if ( $answer{DEBUG} !~ m/true|false/i )
        {
            print "Possible answers are: true or false \n"
              if ( $answer{DEBUG} ne 'NA' );
            return 1;
        }
        $answer{DEBUG} = '0' if ( $answer{DEBUG} eq "false" );
        $answer{DEBUG} = '1' if ( $answer{DEBUG} eq "true" );
        return 0;
    };
    $checkDefault{'MORE_TSM_SERVER'} = sub {
        if ( $answer{MORE_TSM_SERVER} !~ m/yes|no/i )
        {
            print "Possible answers are: yes or no \n" if ( $answer{MORE_TSM_SERVER} ne 'NA' );
            return 1;
        }
        $answer{MORE_TSM_SERVER} = '0' if ( $answer{MORE_TSM_SERVER} =~ m/no/i );
        $answer{MORE_TSM_SERVER} = '1' if ( $answer{MORE_TSM_SERVER} =~ m/yes/i );
        return 0;
    };

    foreach ( keys %question )
    {
        $answer{$_} = 'NA';
    }

    #Subs
    sub getAnswer($)
    {
        my $hashKey = $_[0];
        my $answer  = <STDIN>;
        chomp($answer);
        if ( $answer =~ m/^BACK$/i )
        {
            return "BACK";
        }
        elsif ( $answer =~ m/^NEXT$/i )
        {
            return "NEXT";
        }
        elsif ( $answer =~ m/^QUIT$/i )
        {
            exit 99;
        }
        else
        {
            if ( $answer eq "" )
            {
                $answer = $default{$hashKey};
            }
            return "$answer";
        }
    }

    sub askQuestion()
    {
        my $hashKey = $_[0];
        &{$setDefault{$hashKey}};
        print $description{$hashKey} if ( defined $description{$hashKey} );
        while ( &{$checkDefault{$hashKey}} )
        {
            print "$question{$hashKey} [$default{$hashKey}] : ";
            $answer{$hashKey} = &getAnswer($hashKey);
        }
    }

    sub getTSMServerParameters()
    {
        &askQuestion("TSM_SERVER_NAME");
        $answer{TSM_SERVER_NAME} = uc( $answer{TSM_SERVER_NAME} );

        #$answer{DEFAULTSERVER} = $answer{TSM_SERVER_NAME};
        push( @servers, $answer{TSM_SERVER_NAME} );
        &askQuestion("TSMSERVER");
        $answer{"$answer{TSM_SERVER_NAME}\[TSMSERVER\]"} = $answer{TSMSERVER};
        if ( $^O eq "MSWin32" )
        {
            &askQuestion("TSMPORT");
            $answer{"$answer{TSM_SERVER_NAME}\[TSMPORT\]"} = $answer{TSMPORT};
        }
        &askQuestion("TSMUSERNAME");
        $answer{"$answer{TSM_SERVER_NAME}\[TSMUSERNAME\]"} = $answer{TSMUSERNAME};
        # turn off echo
        ReadMode('noecho');        
        &askQuestion("TSMPASSWORD");
        # turn on echo
        ReadMode('normal');
        $answer{"$answer{TSM_SERVER_NAME}\[TSMPASSWORD\]"} = $answer{TSMPASSWORD};
        $answer{TSM_SERVER_NAME}                           = 'NA';
        $answer{TSMSERVER}                                 = 'NA';
        $answer{TSMPORT}                                   = 'NA';
        $answer{TSMUSERNAME}                               = 'NA';
        $answer{TSMPASSWORD}                               = 'NA';
        $answer{MORE_TSM_SERVER}                           = 'NA';
        return &askQuestion('MORE_TSM_SERVER');
    }

    &askQuestion("DSM_DIR");
    &askQuestion("DSM_LOG");
    &askQuestion("DSM_CONFIG");

### Server sections:

    while (    $answer{MORE_TSM_SERVER} eq "1"
            || $answer{MORE_TSM_SERVER} eq "NA" )
    {
        print "Add a TSM server parameters\n";
        &getTSMServerParameters;
    }

    if ($#servers != 0) {
        &askQuestion("DEFAULTSERVER");        
    } else {
        $answer{DEFAULTSERVER} = $servers[0];
    }


### Print
    if ( !-d dirname($Settings{CONFIGFILE}) ) {
       mkpath dirname($Settings{CONFIGFILE}) or die ;
    }
    open (CONFIGFILE, ">", "$Settings{CONFIGFILE}") or die;

    print ">>>>>>>>>>CONFIG FILE<<<<<<<<<<\n";
    print CONFIGFILE "DEBUG = 0

DEFAULTCOLOR   = WHITE
HEADERCOLOR    = WHITE
HIGHLIGHTCOLOR = RED
AUTOCONNECT    = 1

PROMPT         = TSMADM [SERVERNAME]:

";

    print CONFIGFILE "DSM_DIR = $answer{DSM_DIR}\n";
    print CONFIGFILE "DSM_LOG = $answer{DSM_DIR}\n";
    print CONFIGFILE "DSM_CONFIG = $answer{DSM_CONFIG}\n";
    print CONFIGFILE "DSMADMC = $answer{DSM_DIR}dsmadmc" . ( $OS_win ? '.exe' : '' ) . "\n";
    print CONFIGFILE "\n";
    print CONFIGFILE "DEFAULTSERVER = $answer{DEFAULTSERVER}\n";
    print CONFIGFILE "\n";

    foreach my $server (@servers)
    {

        print CONFIGFILE $server. "[TSMSERVER]   = " . $answer{"$server\[TSMSERVER\]"} . "\n";
        print CONFIGFILE $server. "[TSMPORT]     = " . $answer{"$server\[TSMPORT\]"} . "\n" if ($OS_win);
        print CONFIGFILE $server. "[TSMUSERNAME] = " . $answer{"$server\[TSMUSERNAME\]"} . "\n";
        print CONFIGFILE $server. "[TSMPASSWORD] = " . $answer{"$server\[TSMPASSWORD\]"} . "\n\n";
    }

close (CONFIGFILE) or die;

}


1;
