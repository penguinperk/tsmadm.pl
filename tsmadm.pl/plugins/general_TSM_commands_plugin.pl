#!/usr/bin/perl

use strict;
use warnings;

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

# show session
# show processis
# show scratches
# kill
# reach
# show disks
# show timing
# show drives

# show path
# on off

# show status
# show libvolumes
# show assoc
# delete assoc

#################
# Show SESsions ########################################################################################################
#################
&msg( '0110D', 'SHow SESsions' );
$Commands{&commandRegexp( "show", "sessions" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "show sessions Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @query = &runTabdelDsmadmc( "select SESSION_ID,STATE,WAIT_SECONDS,BYTES_SENT,BYTES_RECEIVED,SESSION_TYPE,CLIENT_PLATFORM,CLIENT_NAME,MOUNT_POINT_WAIT,INPUT_MOUNT_WAIT,INPUT_VOL_WAIT,INPUT_VOL_ACCESS,OUTPUT_MOUNT_WAIT,OUTPUT_VOL_WAIT,OUTPUT_VOL_ACCESS,LAST_VERB,VERB_STATE from sessions order by 1","select_x_from_sessions" );
    #,OWNER_NAME,MOUNT_POINT_WAIT,INPUT_MOUNT_WAIT,INPUT_VOL_WAIT,INPUT_VOL_ACCESS,OUTPUT_MOUNT_WAIT,OUTPUT_VOL_WAIT,OUTPUT_VOL_ACCESS,LAST_VERB,VERB_STATE
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = "SESSION";

    &pbarInit( "PREPARATION |", scalar( @query ), "|");

    my $i = 1;
    my @printable;

    foreach ( @query ) {
        my @line = split ( /\t/ );
        
        $line[2] = ( $line[2] > 600 ) ? &colorString( &timeFormatter ( $line[2], 's' ), "BOLD RED" ) : &timeFormatter ( $line[2], 's' );
        
        $line[3] = &byteFormatter ( $line[3], 'B' );
        $line[4] = &byteFormatter ( $line[4], 'B' );

        $line[8] = "" if ( ! defined ( $line[8] ) );
        $line[9] = "" if ( ! defined ( $line[9] ) );

        my $mediaAccess = $line[8].$line[9].$line[10].$line[11].$line[12].$line[13].$line[14];
                
        my $mediaAccessExtra = '';
        
        if ( $line[8] ne '' ) {
            $mediaAccessExtra = 'w';
        }
        elsif ( $line[9].$line[10].$line[11] ne '' ) {
            $mediaAccessExtra = 'Read';
        }
        elsif ( $line[12].$line[13].$line[14] ne '' ) {
            $mediaAccessExtra = 'Write';
        }
        
        if ( $mediaAccess =~ m/(\w*),(\w+),(\d+)\:(\w*),(\w+),(\d+)/ ) {            
            $mediaAccess = "\[".&colorString( $2, "BOLD GREEN" )."\]".( $1 eq '' ) ? '' : "+[$1]".", ".&timeFormatter ( $3, 's' );
            $mediaAccess .= "\[".&colorString( $5, "BOLD GREEN" )."\]".( $4 eq '' ) ? '' : "+[$4]".", ".&timeFormatter ( $6, 's' );
        }
        elsif ( $mediaAccess =~ m/(\w*),(\w+),(\d+)/ ) {
            my $secondmatch = ( $1 eq '' ) ? '' : "+[$1]";
            $mediaAccess = "\[".&colorString( $2, "BOLD GREEN" )."\]".$secondmatch.", ".&timeFormatter ( $3, 's' );    
        }
        
        $mediaAccess = $mediaAccessExtra.$mediaAccess;
        
        push ( @printable, join( "\t", $line[0], $line[1], $line[2], $line[3], $line[4], $line[5], $line[6], $line[7], $mediaAccess, $line[16].'['.$line[15].']' ) );
        
        &pbarUpdate( $i++ );
    }
  
    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tId\tState\tWait\tSent{RIGHT}\tReceived{RIGHT}\tType\tPlatform\tName\tMediaAccess\tVerb", &addLineNumbers( @printable ) );
    #\tOWNER_NAME\tMOUNT_POINT_WAIT\tINPUT_MOUNT_WAIT\tINPUT_VOL_WAIT\tINPUT_VOL_ACCESS\tOUTPUT_MOUNT_WAIT\tOUTPUT_VOL_WAIT\tOUTPUT_VOL_ACCESS\tLAST_VERB\tVERB_STATE

    return 0;

};
&defineAlias( 'ls',   'show session' );
&defineAlias( 'ps',   'show session' );
&defineAlias( 'ses',  'show session' );
&defineAlias( 'sess', 'show session' );

#################
# SHow PROcesses ########################################################################################################
#################
&msg( '0110D', 'SHow PROcesses' );
$Commands{&commandRegexp( "show", "processes" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow PROcesses Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @query = &runTabdelDsmadmc( "select PROCESS_NUM,PROCESS,FILES_PROCESSED,BYTES_PROCESSED,STATUS from processes order by 1","select_x_from_processes" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = "PROCESS";

    my @printable;

    foreach ( @query ) {
        my @line = split ( /\t/ );

        $line[3] = &byteFormatter ( $line[3], 'B' ) if ( defined( $line[3] ) and $line[3] ne '' );        

        push ( @printable, join( "\t", @line ) )
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tProc#\tProcess\tFiles{RIGHT}\tBytes{RIGHT}\tStatus", &addLineNumbers( @printable ) );

    return 0;

};
&defineAlias( 'q proc', 'show processes' );
&defineAlias( 'qp roc', 'show processes' );
&defineAlias( 'proc',   'show processes' );

##################
# Show SCRatches #######################################################################################################
##################
&msg( '0110D', 'SHow SCRatches' );
$Commands{&commandRegexp( "show", "scratches" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow SCRatches Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }
      
    if ( defined( $Settings{LIBRARYMANAGER} ) && $TSMSeverStatus{SERVERNAME} ne $Settings{LIBRARYMANAGER} ) {
        $ParameterRegExpValues{SERVERCOMMANDROUTING1} = $Settings{LIBRARYMANAGER};
        &msg( '0040I', $Settings{LIBRARYMANAGER} );
    }
   
    my @query = &runTabdelDsmadmc( "select LIBRARY_NAME, MEDIATYPE, count(*) from libvolumes where upper(status)='SCRATCH' group by LIBRARY_NAME,MEDIATYPE", "select_lib_scratches_from_libvolumes" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'GENERAL';

    if ( $ParameterRegExpValues{HISTORY} ) {

        my @archive = &initArchiveRetriever ( 'select_lib_scratches_from_libvolumes' );
        return 0 if ( $#archive < 0 );

        while ( 1 ) {

            my $i = 1;
            my @printable;
            my %librarysumma;
            
            foreach ( @archive ) {
                my @line = split ( /\t/ );
                              
                $librarysumma{$line[0]} += $line[2];
                
                &pbarUpdate( $i++ );
            }    
        
            &pbarInit( "PREPARATION 2|", scalar( @query ), "|");    
            $i = 1;
        
            foreach ( @archive ) {
                my @line = split ( /\t/ );
                       
                push ( @printable, join( "\t", $line[0], $line[1], $librarysumma{$line[0]}."/".$line[2] ) );
                
                &pbarUpdate( $i++ );
            }        
            
            &setSimpleTXTOutput();
            &universalTextPrinter( "LibraryName\tType\t#Scratch{RIGHT}", @printable );
                    
            @archive = &archiveRetriever();
            last if ( $#archive < 0 );

        }

    }
    else {

        &pbarInit( "PREPARATION 1|", scalar( @query ), "|");
    
        my $i = 1;
        my @printable;
        my %librarysumma;
        
        foreach ( @query ) {
            my @line = split ( /\t/ );
                          
            $librarysumma{$line[0]} += $line[2];
            
            &pbarUpdate( $i++ );
        }    
    
        &pbarInit( "PREPARATION 2|", scalar( @query ), "|");    
        $i = 1;
    
        foreach ( @query ) {
            my @line = split ( /\t/ );
                   
            push ( @printable, join( "\t", $line[0], $line[1], $librarysumma{$line[0]}."/".$line[2] ) );
            
            &pbarUpdate( $i++ );
        }        
        
        &setSimpleTXTOutput();
        &universalTextPrinter( "LibraryName\tType\t#Scratch{RIGHT}", @printable );

    }

    return 0;

};
&defineAlias( 'scr', 'show scratches' );

##################
# Show MAXscratch #####################################################################################################
##################
&msg( '0110D', 'SHow MAXscratch' );
$Commands{&commandRegexp( "show", "maxscratch" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow MAXscratch Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @query = &runTabdelDsmadmc( "SELECT STGPOOLS.STGPOOL_NAME, STGPOOLS.MAXSCRATCH, Count(1) FROM STGPOOLS,VOLUMES WHERE (VOLUMES.STGPOOL_NAME = STGPOOLS.STGPOOL_NAME) GROUP BY STGPOOLS.STGPOOL_NAME, STGPOOLS.MAXSCRATCH" );
    return 0 if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'GENERAL';

    if ( $ParameterRegExpValues{HISTORY} ) {

        my @archive = &initArchiveRetriever ( 'select_stgp_scratches_from_stgpvolumes' );
        return 0 if ( $#archive < 0 );

        while ( 1 ) {

            &setSimpleTXTOutput();
            &universalTextPrinter( "StgPool\t#Scratch\t#Volumes", @archive );

            @archive = &archiveRetriever();
            last if ( $#archive < 0 );

        }

    }
    else {

        &setSimpleTXTOutput();
        &universalTextPrinter( "StgPool\t#Scratch\t#Volumes", @query );

    }

    return 0;

};

########
# KIll #######################################################################################################
########
&msg( '0110D', 'KILl' );
$Commands{&commandRegexp( "kill", "" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "KILl Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my $number = $2;

    if ( $number eq '' ) {
        &msg ( '0030E' );  # missing
        return 0;
    }

    if ( defined( $LastCommandType ) && $LastCommandType =~ m/SESSION|PROCESS/ ) {

        if ( $number =~ m/\d+/ ) {

            $number--;

            if (  $number <= $#LastResult ) {

                my ( $num, $session ) = split ( /\t/, $LastResult[$number] );

                #&msg ( '0030I' );
                &universalTextPrinter( "NOHEADER", &runDsmadmc( "cancel $LastCommandType $session" ) );

            }
            else {

                &msg ( '0032E' ); # out of range

            }

        }
        elsif ( uc( $number ) eq 'ALL' ) {

            foreach ( @LastResult ) {
                my ( $num, $session ) = split ( /\t/, $_ );
                &universalTextPrinter( "NOHEADER", &runDsmadmc( "cancel $LastCommandType $session" ) );
            }

        }
        else {
          #wrong parameter

        }
    }
    else {

        &msg ( '0031E', "Only 'SHow Sessions' OR 'SHow PROcesses' allowed" );

    }

    return 0;

};

########
# REAch #######################################################################################################
########
&msg( '0110D', 'REAch' );
$Commands{&commandRegexp( "reach", "" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "REAch Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my $parameter = $2;
    my $extras = ' '.$3.' '.$4.' '.$5;

    if ( defined( $LastCommandType ) && $LastCommandType =~ m/SESSION/ && $parameter =~ m/\d+/ ) {

        my $number = $parameter;

        $number--;

        if ( $number <= $#LastResult ) {

            my ( $num, $session, $state, $wait, $sent, $received, $type, $platform, $node_name ) = split ( /\t/, $LastResult[$number] );

            my @url = &runTabdelDsmadmc( "select URL from NODES where NODE_NAME='".$node_name."'" );

            if ( ! defined ( $url[0] ) || $url[0] eq '' ) {

                &msg ( '0050E', $node_name );

            }
            else {

                &reach ( $url[0] );

            }

        }
        elsif ( $number > $#LastResult ) {

            &msg ( '0032E' ); # out of range

        }
        else {

            &msg ( '0031E', "Only 'SHow Sessions' allowed" );

        }
    }
    elsif ( $parameter =~ m/\w+/ ) {

        my $node_name = uc( $parameter );

        #print "[$node_name]\n";

        my @url = &runTabdelDsmadmc( "select URL from NODES where NODE_NAME='".$node_name."'" );

        if ( ! defined ( $url[0] ) || $url[0] eq '' ) {
            
            &msg ( '0050E', $node_name );
            &reach ( $parameter.$extras );
            
        }
        else {

            &reach ( $url[0] );

        }

    }
    else {

        &msg ( '0030E' );

    }


    return 0;

};

##############
# Show DISks ###########################################################################################################
##############
&msg( '0110D', 'SHow DISks' );
$Commands{&commandRegexp( "show", "disks" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow DISks Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @query = &runTabdelDsmadmc( "select STGPOOL_NAME,DEVCLASS,EST_CAPACITY_MB,PCT_UTILIZED,PCT_MIGR,HIGHMIG,LOWMIG,NEXTSTGPOOL from STGPOOLS where DEVCLASS='DISK'", 'select_x_from_stgpools' );
    return if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'GENERAL';

    my @printable;

    foreach ( deleteColumn( 1, @query ) ) {
      my @line = split ( /\t/ );
      $line[1] = &byteFormatter ( $line[1], 'MB' );
      $line[6] = " " if ( ! defined ( $line[6] ) );
      
      if ( $line[3] >= 40 && $line[3] <= 80 ) {
        $line[3] = &colorString( "$line[3]", "BOLD YELLOW" );
      }
      elsif ( $line[3] > 80 ) {
        $line[3] = &colorString( "$line[3]", "BOLD RED" );
      }
            
      push ( @printable, join( "\t", $line[0], $line[1], $line[2], $line[3], $line[4], $line[5], $line[6] ) );
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tStgPoolName\tEstCap{RIGHT}\tPctUtil{RIGHT}\tPctMig{RIGHT}\tHigh{RIGHT}\tLow{RIGHT}\tNextStgPool", &addLineNumbers( @printable ) );

    return 0;

};
&defineAlias( 'dsk',    'show disks' );
&defineAlias( 's dsk',  'show disks' );
&defineAlias( 'sh dsk', 'show disks' );

#################
# Show STGpools ###########################################################################################################
#################
&msg( '0110D', 'SHow STGpools' );
$Commands{&commandRegexp( "show", "stgpools" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow STGpools Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @query = &runTabdelDsmadmc( "select STGPOOL_NAME,DEVCLASS,COLLOCATE,EST_CAPACITY_MB,PCT_UTILIZED,PCT_MIGR,HIGHMIG,LOWMIG,RECLAIM,NEXTSTGPOOL from STGPOOLS", 'select_x_from_stgpools' );
    return if ( $#query < 0 || $LastErrorcode );

    $LastCommandType = 'GENERAL';

    my @printable;

    foreach ( @query ) {
      my @line = split ( /\t/ );
      $line[3] = &byteFormatter ( $line[3], 'MB' );
      $line[5] = " " if ( ! defined ( $line[5] ) );
      $line[6] = " " if ( ! defined ( $line[6] ) );
      $line[7] = " " if ( ! defined ( $line[7] ) );
      $line[8] = " " if ( ! defined ( $line[8] ) );
      $line[9] = " " if ( ! defined ( $line[9] ) );
      
      if ( $line[1] eq 'DISK' ) {

        if ( $line[5] >= 40 && $line[5] <= 80 ) {
          $line[5] = &colorString( "$line[5]", "BOLD YELLOW" );
        }
        elsif ( $line[5] > 80 ) {
          $line[5] = &colorString( "$line[5]", "BOLD RED" );
        }
        
      }
      else {
        
        if ( $line[4] >= 80 && $line[4] <= 90 ) {
          $line[4] = &colorString( "$line[4]", "BOLD YELLOW" );
        }
        elsif ( $line[4] > 90 ) {
          $line[4] = &colorString( "$line[4]", "BOLD RED" );
        }
        
      }
      
      $line[5] = "------" if ( $line[5] eq '' );
      $line[6] = "----" if ( $line[6] eq '' );
      $line[7] = "---" if ( $line[7] eq '' );
      
      push ( @printable, join( "\t", $line[0], $line[1], $line[2], $line[3], $line[4], $line[5], $line[6], $line[7], $line[8], $line[9] ) );
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tStgPoolName\tDeviceClass\tColl\tEstCap{RIGHT}\tPctUtil{RIGHT}\tPctMig{RIGHT}\tHigh{RIGHT}\tLow{RIGHT}\tRecl{RIGHT}\tNextStgPool{RIGHT}\t ", &addLineNumbers( @printable ) );

    return 0;

};
&defineAlias( 'stgp',    'show stgp' );
&defineAlias( 's stgp',  'show stgp' );
&defineAlias( 'sh stgp', 'show stgp' );

###############
# Show DRIVes ##########################################################################################################
###############
&msg( '0110D', 'SHow DRIves' );
$Commands{&commandRegexp( "show", "drives" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow DRIves Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'DRIVE';

    if ( defined( $Settings{LIBRARYMANAGER} ) && $TSMSeverStatus{SERVERNAME} ne $Settings{LIBRARYMANAGER} ) {
        $ParameterRegExpValues{SERVERCOMMANDROUTING1} = $Settings{LIBRARYMANAGER};
        &msg( '0040I', $Settings{LIBRARYMANAGER} );
    }
        
    my @query = &runTabdelDsmadmc( "select LIBRARY_NAME,DRIVE_NAME,'ONL='||ONLINE,ELEMENT,DRIVE_STATE,DRIVE_SERIAL,VOLUME_NAME,ALLOCATED_TO from drives order by 1,2" );
    return if ( $#query < 0 || $LastErrorcode );

    if ( defined( $Settings{LIBRARYMANAGER} ) && $TSMSeverStatus{SERVERNAME} ne $Settings{LIBRARYMANAGER} ) {
        $ParameterRegExpValues{SERVERCOMMANDROUTING1} = $Settings{LIBRARYMANAGER};
    }
    
    # István added it
    my @query_m = &runDsmadmc( "q mount" );
    chomp( @query_m );

    my $i = 1;
    my %vols;
        
    &pbarInit( "PREPARATION  I. |", scalar( @query_m ), "|");
    
    foreach ( @query_m ) {
       
       if ( $_ =~ m/^ANR83{29|30|31|32|33}I/ ) {
           if ( $_ =~ /.*volume (.*) is mounted (.*) in drive.*, status: (.*)\./ ) {
                $vols{$1}[0]=$2;
                $vols{$1}[1]=$3;
           }
       }
       
       &pbarUpdate( $i++ );
    }
    
    $i = 1;
    my @printable;
    
    &pbarInit( "PREPARATION II. |", scalar( @query ), "|");
    
    foreach ( @query ) {
        my @line = split ( /\t/ );

        if ( defined ( $line[6] ) && exists ( $vols{$line[6]} ) ) {
            
            $line[8] = $vols{$line[6]}[0];
            $line[9] = $vols{$line[6]}[1];
            
        }

        if ( defined ( $line[6] ) and $line[6] ne '' ) {
            
            # route the command if it necessary
            $ParameterRegExpValues{SERVERCOMMANDROUTING1} = '';
            $ParameterRegExpValues{SERVERCOMMANDROUTING1} = $line[7] if ( defined ( $line[7]) && $TSMSeverStatus{SERVERNAME} ne $line[7] );

            # my @query_sess = &runTabdelDsmadmc( "select SESSION_ID from sessions where INPUT_MOUNT_WAIT like '%$line[6]%' or INPUT_VOL_WAIT like '%$line[6]%' or INPUT_VOL_ACCESS like '%$line[6]%' or OUTPUT_MOUNT_WAIT like '%$line[6]%' or OUTPUT_VOL_WAIT like '%$line[6]%' or OUTPUT_VOL_ACCESS like '%$line[6]%'" );
            # this select doesn't work on Lan-FREE
            my $isSessionMediaW = "";
            my @query_sess = grep( /$line[6]/i, &runTabdelDsmadmc( "q session f=d" ) );
            if ( $LastErrorcode == 0 && defined ( $query_sess[0] ) ) {
                my @tmpline = split ( /\t/, $query_sess[0] );
                $tmpline[0] =~ s/,//g;
                $line[10] = "Client ($tmpline[0])";
                $isSessionMediaW = $tmpline[2] if ( $tmpline[2] eq 'MediaW' );
            }
            
            my @query_pr = &runTabdelDsmadmc( "select PROCESS,PROCESS_NUM from processes where STATUS like '%$line[6]%'" );
            if ( $LastErrorcode == 0 && defined ( $query_pr[0] ) and $query_pr[0] !~ m/^ANR3604E/ ) {
                my @tmpline = split ( /\t/, $query_pr[0] );
                if ( $isSessionMediaW eq "MediaW" ) {
                    $line[10] = "$tmpline[0] ($tmpline[1]) + ".$line[10]." MediaW!";
                }
                else {
                    $line[10] = "$tmpline[0] ($tmpline[1])";
                }
                
            }
             
            # message based highlighter v3
            #$line[6] = '['.$line[6].']';
            $line[6] = &colorString( $line[6], "BOLD GREEN" );;
            
        }
        
        # fill
        $line[3]  = " " if ( ! defined ( $line[3] ) );
        $line[4]  = " " if ( ! defined ( $line[4] ) );
        $line[5]  = " " if ( ! defined ( $line[5] ) );
        $line[6]  = " " if ( ! defined ( $line[6] ) );
        
        $line[7]  = " " if ( ! defined ( $line[7] ) );
        $line[8]  = " " if ( ! defined ( $line[8] ) );
        $line[9]  = " " if ( ! defined ( $line[9] ) );
        $line[10] = " " if ( ! defined ( $line[10] ) );
        $line[10] =~ s/Storage Pool/Stgp/;

        push ( @printable, join ( "\t", @line ) );
        
        &pbarUpdate( $i++ );
        
    }
    
    my $level = 1;
    $i = 0;
    foreach ( @printable ) {
        my @line = split ( /\t/ );
        
        if ( defined ( $line[10] ) && $line[10] ne ' ' ) {
            
            # force \(\) for good regexp matching
            $line[10] =~ s/\(/\\(/;
            $line[10] =~ s/\)/\\)/;
            
            # find pair
            for ( my $index = $i+1; $index <= $#printable; $index++ ) {
                my @printableline = split ( /\t/, $printable[$index] );
               
                if ( defined ( $printableline[10]) && $printableline[10] ne " " && $printableline[10] =~ m/$line[10].*/ ) {
                    # pair found $i start, $index end
                    $printable[$i] .= ( $level == 1 ) ? "\t+" : "+";
                    for ( my $index2 = $i+1; $index2 <= $index-1; $index2++ ) {
                        $printable[$index2] .= ( $level == 1 ) ? "\t|" : "|";
                    }
                    $printable[$index] .= ( $level == 1 ) ? "\t+" : "+";
                    #rest
                    for ( my $index3 = $index+1; $index3 <= $#printable; $index3++ ) {
                        $printable[$index3] .= ( $level == 1 ) ? "\t " : " ";
                    }
                        
                    $level++;
                    
                }
            }
            
        }
        
        $i++;
        
    }
    
    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tLibraryName\tDriveName\tOnline\t#El\tState\tSerial\tVolume{RIGHT}\tOwner\tMod{RIGHT}\tMStatus{RIGHT}\tRemark{RIGHT}\t ", &addLineNumbers( @printable ) );

    return 0;

};
&defineAlias( 's drive', 'show drives' );

########################################################################################################################

##############
# Show PAThs ###########################################################################################################
##############
&msg( '0110D', 'SHow PAThs' );
$Commands{&commandRegexp( "show", "paths" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow PAThs Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'PATH';

    my @query = &runTabdelDsmadmc( "select SOURCE_NAME,DESTINATION_NAME,'SRCT='||SOURCE_TYPE,'DESTT='||DESTINATION_TYPE,LIBRARY_NAME,'DEVI='||DEVICE,'ONL='||ONLINE from paths where LIBRARY_NAME is null" );
    if ( $LastErrorcode ) {
        # check valid libraries like ACSLS and override this LastErrorcode and continue
        my @tmpQuery = &runTabdelDsmadmc( "select LIBRARY_NAME from LIBRARIES" );
        if ( $LastErrorcode ) {
            return;    
        }
    }

    push ( @query, &runTabdelDsmadmc( "select SOURCE_NAME,DESTINATION_NAME,'SRCT='||SOURCE_TYPE,'DESTT='||DESTINATION_TYPE,'LIBR='||LIBRARY_NAME,'DEVI='||DEVICE,'ONL='||ONLINE from paths where LIBRARY_NAME is not null" ) );
    return if ( $#query < 0 || $LastErrorcode );

    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tSourceName\tDestiName\tSourceType\tDestinationType\tLibraryName\tDevice\tOnline", &addLineNumbers( @query ) );

    return 0;

};
&defineAlias( 's path', 'show path' );

########################################################################################################################

##########
# ONline ################################################################################################################
##########
&msg( '0110D', 'ONLine' );
$Commands{&commandRegexp( "online", "" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "ONLine Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my $number = $2;

    if ( $number eq '' ) {
        &msg ( '0030E' );
        return 0;
    }

    $number--;

    if ( defined( $LastCommandType ) && $LastCommandType =~ m/DRIVE|PATH/ && $number <= $#LastResult ) {

        my @line = split ( /\t/, $LastResult[$number] );

        &setSimpleTXTOutput();
        &universalTextPrinter( "NOHEADER", &runDsmadmc( "update path  $line[1] $line[2] $line[3] $line[4] $line[5] online=yes") ) if ( $LastCommandType eq 'PATH' );
        &universalTextPrinter( "NOHEADER", &runDsmadmc( "update drive $line[1] $line[2] online=yes" ) )                           if ( $LastCommandType eq 'DRIVE' );

    }
    elsif ( $number > $#LastResult ) {

        &msg ( '0032E' ); # out of range

    }
    else {

        &msg ( '0031E', "Only 'SHow PAThs' OR 'SHow DRIves' allowed" );

    }

    return 0;

};
&defineAlias( 'on', 'online' );

########################################################################################################################

###########
# OFFline ##############################################################################################################
###########
&msg( '0110D', 'OFFline' );
$Commands{&commandRegexp( "offline", "" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "OFFline Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my $number = $2;

    if ( $number eq '' ) {
        &msg ( '0030E' );
        return 0;
    }

    $number--;

    if ( defined( $LastCommandType ) && $LastCommandType =~ m/DRIVE|PATH/ && $number <= $#LastResult ) {

        my @line = split ( /\t/, $LastResult[$number] );

        &setSimpleTXTOutput();
        &universalTextPrinter( "NOHEADER", &runDsmadmc( "update path  $line[1] $line[2] $line[3] $line[4] $line[5] online=no" ) ) if ( $LastCommandType eq 'PATH' );
        &universalTextPrinter( "NOHEADER", &runDsmadmc( "update drive $line[1] $line[2] online=no" ) )                            if ( $LastCommandType eq 'DRIVE' );

    }
    elsif ( $number > $#LastResult ) {

        &msg ( '0032E' ); # out of range

    }
    else {

        &msg ( '0031E', "Only 'SHow PAThs' OR 'SHow DRIves' allowed" );

    }

    return 0;

};
&defineAlias( 'of', 'offline' );

########################################################################################################################

#################
# STart DSMadmc ###########################################################################################################
#################
&msg( '0110D', 'STart DSMadmc' );
$Commands{&commandRegexp( "start", "dsmadmc" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "STart DSMadmc Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'GENERAL';

    if ( $3 =~ m/(nologin|no)/i ) {
        &startDsmadmc( );
    }
    else {
        &startDsmadmc( 'AUTOLOGIN' );
    }

    return 0;

};
&defineAlias( 'dsm', 'start dsmadmc' );

###############
# SHow EVEnts ##########################################################################################################
###############
&msg( '0110D', 'SHow EVEnts' );
$Commands{&commandRegexp( "show", "events" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow EVEnts Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'EVENTS';

    my @query = &runTabdelDsmadmc('q event * * begint=-24 endd=today endt=now f=d '.$3.' '.$4.' '.$5);
    return if ( $#query < 0 || $LastErrorcode );

    @query = deleteColumn( 8, @query);

    &pbarInit( "PREPARATION |", scalar( @query ), "|");

    my $i = 1;
    my @printable;
    
    foreach ( @query ) {
        my @line = split(/\t/);

        $line[7] = '' if  ( ! defined ( $line[7] ) );

        if ( $line[3] =~ m/(\d\d\/\d\d\/\d\d\d\d\s*)/ ) {
            my $date = $1;
            $line[4] =~ s/$date//;
            $line[5] =~ s/$date//;
        }
        
        if ( $line[6] =~ m/completed/i ) {
            if ( $line[7] == 4 || $line[7] == 8 ) {
                $line[7] = &colorString( $line[7], "BOLD YELLOW" );
            }
        }
        elsif ( $line[6] =~ m/missed/i ) {
            $line[6] = &colorString( $line[6], "BOLD YELLOW" );
        }
        elsif ( $line[6] =~ m/failed/i ) {
            $line[6] = &colorString( $line[6], "BOLD RED" );
            $line[7] = &colorString( $line[7], "BOLD RED" );
        }
        elsif ( $line[6] =~ m/severed/i ) {
            $line[6] = &colorString( $line[6], "BOLD RED" );
            $line[7] = &colorString( $line[7], "BOLD RED" );
        }
        elsif ( $line[6] =~ m/started/i ) {
            $line[6] = &colorString( $line[6], "BOLD GREEN" );
        }
        elsif ( $line[6] =~ m/pending/i ) {
            $line[6] = &colorString( $line[6], "GREEN" );
        }

        push ( @printable, join( "\t", @line ) );

        &pbarUpdate( $i++ );

    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tDomain\tScheduleName\tNodeName\tScheduledStart\tActStart{RIGHT}\tCompleted{RIGHT}\tStatus\tRC{RIGHT}", &addLineNumbers( @printable ) );

    return 0;

};
&defineAlias( 'sh exc', 'show events exc=yes' );

########################################################################################################################

####################
# SHow ADMINEVEnts ##########################################################################################################
####################
&msg( '0110D', 'SHow ADMINEVEnts' );
$Commands{&commandRegexp( "show", "adminevents", 2, 8)} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow ADMINEVEnts Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'EVENTS';

    my @query = &runTabdelDsmadmc('q event * begint=-24 endd=today endt=now t=a f=d '.$3.' '.$4.' '.$5);
    return if ( $#query < 0 || $LastErrorcode );

    @query = deleteColumn( 8, @query);

    &pbarInit( "PREPARATION |", scalar( @query ), "|");

    my $i = 1;
    my @printable;
    
    foreach ( deleteColumn( 6, @query ) ) {
        my @line = split(/\t/);

        $line[5] = '' if  ( ! defined ( $line[5] ) );

        if ( $line[1] =~ m/(\d\d\/\d\d\/\d\d\d\d\s*)/ ) {
            my $date = $1;
            $line[2] =~ s/$date//;
            $line[3] =~ s/$date//;
        }
        
        if ( $line[4] =~ m/completed/i ) {
            if ( $line[5] == 4 || $line[5] == 8 ) {
                $line[5] = &colorString( $line[5], "BOLD YELLOW" );
            }
        }
        elsif ( $line[4] =~ m/missed/i ) {
            $line[4] = &colorString( $line[4], "BOLD YELLOW" );
        }
        elsif ( $line[4] =~ m/failed/i ) {
            $line[4] = &colorString( $line[4], "BOLD RED" );
            $line[5] = &colorString( $line[5], "BOLD RED" );
        }
        elsif ( $line[4] =~ m/severed/i ) {
            $line[4] = &colorString( $line[4], "BOLD RED" );
            $line[5] = &colorString( $line[5], "BOLD RED" );
        }
        elsif ( $line[4] =~ m/started/i ) {
            $line[4] = &colorString( $line[4], "BOLD GREEN" );
        }
        elsif ( $line[4] =~ m/pending/i ) {
            $line[4] = &colorString( $line[4], "GREEN" );
        }

        push ( @printable, join( "\t", @line ) );

        &pbarUpdate( $i++ );

    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tScheduleName\tScheduledStart\tActStart{RIGHT}\tCompleted{RIGHT}\tStatus\tRC{RIGHT}", &addLineNumbers( @printable ) );

    return 0;

};

########################################################################################################################

###################
# SHow LIBVolumes ##########################################################################################################
###################
&msg( '0110D', 'SHow LIBVolumes' );
$Commands{&commandRegexp( "show", "libvolumes" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "show libvolumes Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    # save
    my $tmp1 = $ParameterRegExpValues{SERVERCOMMANDROUTING1};
    my $tmp2 = $ParameterRegExpValues{SERVERCOMMANDROUTING2};
    
    if ( defined( $Settings{LIBRARYMANAGER} ) && $TSMSeverStatus{SERVERNAME} ne $Settings{LIBRARYMANAGER} ) {
        $ParameterRegExpValues{SERVERCOMMANDROUTING1} = $Settings{LIBRARYMANAGER};
        &msg( '0040I', $Settings{LIBRARYMANAGER} );
    }
    
    my @libvolumes = &runTabdelDsmadmc( "select volume_name, library_name from libvolumes", "select_vol_lib_from_libvolumes" );
    
    # restore
    $ParameterRegExpValues{SERVERCOMMANDROUTING1} = $tmp1;
    $ParameterRegExpValues{SERVERCOMMANDROUTING2} = $tmp2;
    
    my @volumes    = &runTabdelDsmadmc( "select volume_name, stgpool_name from volumes where devclass_name != 'DISK'" );

    my %tmpLibvolumeHash;

    my @tmp;

    my $i;

    # array2hash
    &pbarInit( "LIBVOLUMES |", scalar( @libvolumes ), "|");

    $i = 1;
    foreach (@libvolumes) {
        my ( $volume_name, $libarry_name ) = split( /\t/, $_ );
        $tmpLibvolumeHash{$volume_name} = $libarry_name;
        &pbarUpdate($i++);
    }

    # "join"
    &pbarInit( "VOLUMES    |", scalar( @volumes ), "|");
    $i = 1;
    my $missingString = &colorString( "!MISSING!", "BOLD RED" );
    foreach (@volumes) {
        my ( $volume_name, $stgpool_name ) = split( /\t/, $_ );
        if ( defined( $tmpLibvolumeHash{$volume_name} ) ) {
#          delete $tmpLibvolumeHash{$volume_name};
        }
        else {
            push( @tmp, "$volume_name\t$stgpool_name\t$missingString" );
        }
        &pbarUpdate( $i++ );
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "VOLUME\tSTGPOOL\tLIBRARY", @tmp );

    $LastCommandType = "GENERAL";

    return 0;

};

##################
# Show SCHedules ######################################################################################################
##################
&msg( '0110D', 'SHow SCHedules' );
$Commands{&commandRegexp( "show", "schedules" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow SCHedules Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'SCHEDULES';

    my @query = &runTabdelDsmadmc( 'q sched '.$3 );
    return if ( $#query < 0 || $LastErrorcode );

    &setSimpleTXTOutput();
    &universalTextPrinter( "Domain\tScheduleName\tAction\tStartDateTime\tDuration\tPeriod\tDay", &deleteColumn( 1, @query ) );

    return 0;

};

########################################################################################################################

###################
# SHow EXPiration ######################################################################################################
###################
&msg( '0110D', 'SHow EXPiration' );
$Commands{&commandRegexp( "show", "expiration" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow EXPiration Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'EXPIRATION';

    my @query = &runTabdelDsmadmc( "select START_TIME, END_TIME-START_TIME as DURATION, SUCCESSFUL, EXAMINED, AFFECTED from Summary where ACTIVITY ='EXPIRATION'", 'select_EXPIRATION_from_summary' );
    return if ( $#query < 0 || $LastErrorcode );

    my @printable;

    foreach ( @query ) {
        my $line = $_;
        $line =~ s/\.000000//g;
        push ( @printable, $line );
    }

    &setSimpleTXTOutput();
    &universalTextPrinter( "StartTime\tDuration\tSuccess{RIGHT}\tExamined{RIGHT}\tAffected{RIGHT}", @printable );

    return 0;

};

########################################################################################################################

#################
# Show FILlings ########################################################################################################
#################
&msg( '0110D', 'SHow FILlings' );
my %filling_tresholds;
$Commands{&commandRegexp( "show", "fillings" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow FILlings Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my $stg = $3;

    my @tmpquery = &runTabdelDsmadmc( "select stgpool_name, count(*) from volumes where stgpool_name like upper\('%$stg%'\) and status='FILLING' and ACCESS='READWRITE' and devclass_name in (select devclass_name from devclasses where WORM='NO' and DEVCLASS_NAME !='DISK') group by STGPOOL_NAME order by 2 desc" );
    return if ( $#tmpquery < 0 || $LastErrorcode );

    $LastCommandType = 'FILLING';
  
    my @printable;
    my @laststore;
    my $counter = 1;

    # add the deltas
    for ( @tmpquery ) {
        my @line = split( /\t/ );

        # filling tresholds
        if ( ( $line[1] <= 1 ) || ( defined $filling_tresholds{$line[0]} && $filling_tresholds{$line[0]} >= $line[1] ) ) {
#          push (@line, '  OK');
#         push (@return, join(',', @line))
        }
        else {
            # stgp header
            # $line[0] = "$line[0] $line[1]/$filling_tresholds{$line[0]}" if ( defined $filling_tresholds{$line[0]} );
            push ( @printable, "\t$line[0] ($line[1])\tFAILED" );

            for ( &runTabdelDsmadmc( "select VOLUME_NAME, PCT_UTILIZED from volumes where STGPOOL_NAME='$line[0]' and STATUS='FILLING' and ACCESS='READWRITE' order by PCT_UTILIZED" ) ) {
                my @line = split(/\t/);
                push ( @printable, "$counter\t\ [$line[0]\] \[$line[1]\]" );
                push ( @laststore, $line[0] );
                $counter++;
            }
        }
    }

  &setSimpleTXTOutput();
  &universalTextPrinter( "#{RIGHT}\tFillingVolume#\tResult", @printable );

  &addLineNumbers( @laststore );  # put all lines to lastresult array

  return 0;
  
};

########################################################################################################################

##########
# MOveit ################################################################################################################
##########
&msg( '0110D', 'MOveit' );
$Commands{&commandRegexp( "moveit", "" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "MOveit Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    # ignore it if 'move data' is supposed to be used
    return 1 if ( $2 =~ m/dat|data/i );

    my $number = $2;

    if ( $number eq '' ) {
        &msg ( '0030E' );
        return 0;
    }

    if ( $number =~ m/\w\w\w\w\w\w/ || $number =~ m/\w\w\w\w\w\w\w\w/ ) {
        
        &setSimpleTXTOutput();
        &universalTextPrinter( "NOHEADER", &runDsmadmc( "move data $number" ) );
        
        return 0;
    }

    $number--;

    if ( defined( $LastCommandType ) && $LastCommandType eq 'FILLING' && $number =~ m/^\d+$/ && $number <= $#LastResult ) {

        my @line = split ( /\t/, $LastResult[$number] );

        &setSimpleTXTOutput();
        &universalTextPrinter( "NOHEADER", &runDsmadmc( "move data $line[1]" ) ) if ( $LastCommandType eq 'FILLING' );

    }
    elsif ( $number > $#LastResult ) {

        &msg ( '0032E' ); # out of range

    }
    elsif ( $number !~ m/^\d+$/ ) {
        
        &msg ( '0034E' ); # wrong parameter
        
    }
    else {

        &msg ( '0031E', "Only 'SHow FILlings' allowed" );

    }

    return 0;

};

########################################################################################################################

###############
# Show TIMIng ##########################################################################################################
###############
&msg( '0110D', 'SHow DISks' );
$Commands{&commandRegexp( "show", "timing" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow TIMing Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    my @return;

    $LastCommandType = 'GENERAL';

    my @query = &runTabdelDsmadmc('q event * * begint=-24 endd=today endt=now f=d '.$3.' '.$4.' '. $5);
    return if ( $#query < 0 || $LastErrorcode );

    my @line;

    my $first_time;
    @line = split( /\t/, $query[0] );
    $first_time = &convert_date( $line[3] );

    my $last_time = $first_time;
    #@line = split( /\t/, $query[$#query] );
    #if ( $line[5] ne '' ) {
    #    $last_time = &convert_date( $line[5] );
    #}
    #else {
    #    $last_time = &convert_date( $line[3] );
    #}

    &pbarInit( "PASS 1 |", scalar( @query ), "|");

    my @maxlength;
    $maxlength[0] = $maxlength[3] = 1;
    $maxlength[1] = length( "ScheduleName" );
    $maxlength[2] = length( "NodeName" );
    
    my $i = 0;
    foreach ( @query ) {

        my @line = split( /\t/ );

        $line[7] = '?' if ( ! defined $line[7] );

        my $number = $i + 1;
        my $length;
        
        $length = colorLength( "$number" );
        $maxlength[0] = $length if ( $length > $maxlength[0] );
        #
        $length = colorLength( "$line[1]" );
        $maxlength[1] = $length if ( $length > $maxlength[1] );
        #
        $length = colorLength( "$line[2]" );
        $maxlength[2] = $length if ( $length > $maxlength[2] );
        #
        $length = colorLength( "$line[7]" );
        $maxlength[3] = $length if ( $length > $maxlength[3] );
     
        # find the oldest time
        my $tmpLast_time;
        if ( $line[5] ne '' ) {
            $tmpLast_time = &convert_date( $line[5] );
        }
        else {
            $tmpLast_time = &convert_date( $line[3] );
        }
        $last_time = $tmpLast_time if ( $tmpLast_time > $last_time );
             
        &pbarUpdate( ++$i );

    }
    
    my $size = $Settings{TERMINALCOLS} - $maxlength[0] - $maxlength[1] - $maxlength[2] - $maxlength[3] - 6 - 2 - 1; # ? 10

    my $quantum = $size;
    $quantum = $quantum / ( $last_time - $first_time ) if ( $last_time - $first_time > 0 );

    &pbarInit( "PASS 2 |", $size, "|");

    # create an empty bar line
    my @emptybar;
    for ( my $i = 0; $i <= $size; $i++ ) {
        $emptybar[$i] = ' ';
        &pbarUpdate( $i );
    }

    &pbarInit( "PASS 3 |", scalar( @query ), "|");

    $i = 0;
    for ( @query ) {
        my @line = split(/\t/);

        my @bar = @emptybar;

        $bar[int( ( &convert_date( $line[3] ) - $first_time ) * $quantum )] = 'S';

        if ( $line[6] =~ m/Future/i ) {
            &fill_bar(\@bar, int((&convert_date($line[3])-$first_time)*$quantum), $size, 'f')
        }

        if ( $line[6] =~ m/Missed/i ) {
            &fill_bar(\@bar, int((&convert_date($line[3])-$first_time)*$quantum), $size, 'M')
        }

        if ( $line[6] =~ m/(C|F)(ompleted|ailed)/i ) {
            &fill_bar(\@bar, int((&convert_date($line[3])-$first_time)*$quantum), int((&convert_date($line[4])-$first_time)*$quantum), 'w');
            &fill_bar(\@bar, int((&convert_date($line[4])-$first_time)*$quantum), int((&convert_date($line[5])-$first_time)*$quantum), 'r');

            $bar[int((&convert_date($line[4])-$first_time)*$quantum)] = 'A';
            $bar[int((&convert_date($line[5])-$first_time)*$quantum)] = "$1";
        }

        if ( ! defined $line[7] ) {
            $line[7] = &colorString( '>', "GREEN" )
        }
        else {
            if ( $line[7] == 0 ) {
                    $line[7] = &colorString( $line[7], "GREEN" );
            }
            elsif ( $line[7] == 4 || $line[7] == 8 ) {
                    $line[7] = &colorString( $line[7], "BOLD YELLOW" );
            }
            else {
                $line[7] = &colorString( $line[7], "BOLD RED" );
            }
        }
        
        push( @return, join( "\t", ++$i, $line[1], $line[2], '|'.join("", @bar).'|', $line[7] ));

        &pbarUpdate( $i );

    }

    # "---\nS-ScheduleStart A-ActualStart r-Running C-Completed, F-Failed, M-Missed, f-furure\n";
    &setSimpleTXTOutput();
    &universalTextPrinter( "#{RIGHT}\tScheduleName\tNodeName\tTiming\tR{RIGHT}", @return );

    return 0;

};

sub convert_date ($) {
  my $tmpdate = $_[0];

  return if ( ! defined $tmpdate || $tmpdate eq '' );

  $tmpdate =~ m/(\d\d)\/(\d\d)\/.*(\d\d) +(\d\d):(\d\d):(\d\d)/;
  return timelocal( $6, $5, $4, $2, $1-1, $3 );

};

sub fill_bar ( $$$$ ) {
    my $r_array   = $_[0];
    my $first_poz = $_[1];
    my $last_poz  = $_[2];
    my $value     = $_[3];

    for ( my $i = $first_poz; $i <= $last_poz; $i++ ) {
        @$r_array[$i] = $value;
    }
}

########################################################################################################################

#################
# SHow INActive ########################################################################################################
#################
&msg( '0110D', 'SHow INActive' );
$Commands{&commandRegexp( "show", "inactive" )} = sub {

    if ( $ParameterRegExpValues{HELP} ) {
        ###############################
        # Put your help message here! #
        ###############################
        print "--------\n";
        print "SHow INActive Help!\n";
        print "--------\n";

        $LastCommandType = "HELP";

        return 0;
    }

    $LastCommandType = 'GENERAL';

    my $days = 15;
    $days = $1 if ( defined $3 && $3 =~ m/(\d+)/ );    
    
    #my @query = &runTabdelDsmadmc('select domain_name, node_name,locked,date(lastacc_time),date(days(CURRENT_DATE))-date(LASTACC_TIME) from nodes where cast((current_timestamp-lastacc_time)days as decimal) >= '.$days.' order by 5 desc');
    my @query; 
    if ( $TSMSeverStatus{VERSION} <= 5 ) {
       @query = &runTabdelDsmadmc( 'select n.domain_name,n.node_name,locked,date(n.lastacc_time),date(days(CURRENT_DATE))-date(n.lastacc_time),o.type,sum(logical_mb),sum(o.num_files) from nodes as n, occupancy as o where n.node_name=o.node_name and cast((current_timestamp-n.lastacc_time)days as decimal) >='.$days.' group by n.domain_name,n.node_name,n.locked,n.lastacc_time,o.type order by 7 desc' ); 
    } else {
       # TIMESTAMPDIFF scalar function: http://publib.boulder.ibm.com/infocenter/db2luw/v9r5/index.jsp?topic=%2Fcom.ibm.db2.luw.sql.ref.doc%2Fdoc%2Fr0000861.html
       @query = &runTabdelDsmadmc( 'select n.domain_name,n.node_name,locked,date(n.lastacc_time),TIMESTAMPDIFF(16,CHAR(current_timestamp-n.lastacc_time)),o.type,sum(logical_mb),sum(o.num_files) from nodes as n, occupancy as o where n.node_name=o.node_name and TIMESTAMPDIFF(16,CHAR(current_timestamp-n.lastacc_time))>=15 group by n.domain_name,n.node_name,n.locked,n.lastacc_time,o.type order by 7 desc' ); 
    }  
    return if ( $#query < 0 || $LastErrorcode );
    
    $LastCommandType = 'INACTIVE';
    
    my @printable;
    
    foreach ( @query ) {
        my @line = split ( /\t/ );
         push ( @printable, join( "\t", $line[0], $line[1],  $line[2],  $line[3], $line[4], $line[5], ( $line[6] > 0 ) ? &byteFormatter( $line[6], 'MB') : "", $line[7] ));
    }
    
    &setSimpleTXTOutput();
    &universalTextPrinter( "DomainName\tNodeName\tLocked?\tLastAccessTime\tDays\tType\t#Data\tFiles", @printable );

    return 0;
};

########################################################################################################################

1;