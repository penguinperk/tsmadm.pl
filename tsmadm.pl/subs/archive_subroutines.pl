#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use Term::ReadKey;
use Time::Local;

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

use constant {
              MIN   => 60,
              HOUR  => 60 * 60,
              DAY   => 24 * 60 * 60,
              MONTH => 30 * 24 * 60 * 60,
              YEAR  => 365 * 24 * 60 * 60
             };

my @archFiles;       # File names
my $archDir;         # The name of the directory
my @archEpoch;       # Epoch times of entries
my $totalEntries;    # total number of entries (files)
my $currentEntry;    # Current entry number (numbered from #1 (?))
my $currentStep    = 1;    # 1(1,i), 10(0,x), 100(c)
my $archiverInited = 0;    # 0: not inited; 1: inited

sub initArchiveRetriever
{

    # receives selector string (a directory name)
    # initializes the Archive Retriever function
    # returns contents of latest file in the form of an array or empty array

    my ($selector) = @_;    # receive args

    my @lastEntry;

    $archDir = File::Spec->catdir( $Settings{ARCHIVEDIRECTORY}, $selector );

    # calculate and print statistics

    opendir my ($dh), $archDir or die "Couldn't open directory\n";
    @archFiles = grep { !/^\.\.?$/ } readdir($dh);
    closedir($dh);

    @archFiles = sort(@archFiles);

    $totalEntries = @archFiles;
    if ( $totalEntries == 0 )
    {
        $currentEntry = 0;
        return @lastEntry;    # returns empty array
    }

    &msg('0044I');

    &msg( '0040I', $totalEntries );
    my ( $archDate, $archHour ) = &getDateHour( $archFiles[0] );    # first entry
    &msg( '0041I', $archDate, $archHour );
    ( $archDate, $archHour ) = &getDateHour( $archFiles[-1] );      # last entry
    &msg( '0042I', $archDate, $archHour );

    my $retEpoch;
    my $prevRetEpoch;
    my @deviation;
    my $i   = 0;
    my $sum = 0;
    foreach (@archFiles)
    {
        $retEpoch = &getEpoch($_);
        push( @archEpoch, $retEpoch );
        if ( $i > 0 )
        {
            $sum += $retEpoch - $prevRetEpoch;
        }
        $prevRetEpoch = $retEpoch;
        $i++;
    }
    my $avg = $sum / $i;

    &msg( '0043I', int($avg), &getReadableTime($avg) );

    my $lastEntryFile = File::Spec->catfile( $archDir, $archFiles[-1] );

    @lastEntry = &file2Array($lastEntryFile);

    $currentEntry = $totalEntries;

    return @lastEntry;

}

sub archiveRetriever
{

    # kiír
    # #bejegyzes sorszama (legujabb kapja a legmagasabb erteket, a legregebbi az #1)
    # az aktualis bejegyzes datuma
    # az aktualis bejegyzes ideje
    # lepes kijelzese: 1, 10, vagy 100
    # lepes modositasa: 1,i->1; 0,x->10; c->100
    # navigacios utmutato: r: érték kiirasa; q: kilepes arc modbol; ?: help
    # "> #nnnn yyyy.mm.dd hh:mm:ss (1)(10)(100) <- -> q r ? <"

    my @return;
    &printControlHeader;

    ReadMode('cbreak');
    my $input = "";
    my @chars;
    while ( push( @chars, ord( ReadKey(0) ) ) )
    {

        if ( ( $chars[-1] == 68 && $chars[-2] == 91 && $chars[-3] == 27 ) || $chars[-1] == 104 )
        {

            # LEFT, one step backward in time
            my $prevEntry = $currentEntry;
            $currentEntry -= $currentStep if ( $currentEntry - $currentStep >= 1 );
            $currentEntry = 1 if ( $currentEntry - $currentStep < 1 );
            &printControlHeader if ( $prevEntry != $currentEntry );

            # control not returned
        }
        elsif ( ( $chars[-1] == 67 && $chars[-2] == 91 && $chars[-3] == 27 ) || $chars[-1] == 108 )
        {

            # RIGHT, one step forward in time
            my $prevEntry = $currentEntry;
            $currentEntry += $currentStep if ( $currentEntry + $currentStep <= $totalEntries );
            $currentEntry = $totalEntries if ( $currentEntry + $currentStep > $totalEntries );
            &printControlHeader if ( $prevEntry != $currentEntry );

            # control not returned
        }
        elsif ( $chars[-1] == 49 || $chars[-1] == 105 )
        {

            # 1 or i
            if ( $currentStep != 1 )
            {
                $currentStep = 1;
                &printControlHeader;

                # control is not returned
            }
        }
        elsif ( $chars[-1] == 48 || $chars[-1] == 120 )
        {

            # 0 or x
            if ( $currentStep != 10 )
            {
                $currentStep = 10;
                &printControlHeader;

                # control is not returned
            }
        }
        elsif ( $chars[-1] == 99 )
        {

            # c
            if ( $currentStep != 100 )
            {
                $currentStep = 100;
                &printControlHeader;

                # control is not returned
            }
        }
        elsif ( $chars[-1] == 114 )
        {

            # r
            my $archEntryFile = File::Spec->catfile( $archDir, $archFiles[$currentEntry - 1] );
            @return = &file2Array($archEntryFile);
            print "\n";
            last;    # control returned
        }
        elsif ( $chars[-1] == 63 )
        {

            # ?
            print "\n";
            &msg('0046I');
            &msg('0047I');
            &msg('0048I');
            &msg('0049I');
            &msg('0050I');
            &msg('0051I');
            &msg('0052I');
            &msg('0053I');
            &msg('0054I');
            &printControlHeader;

            # control is not returned, waiting for next command
        }
        elsif ( $chars[-1] == 113 )
        {

            # q
            print "\n";
            &msg('0045I');

            # @return remains empty
            $archiverInited = 0;
            last;    # control returned
        }
    }
    ReadMode('normal');

    return @return;

}

sub file2Array
{

    # receives file name string
    # returns file loaded into array line by line

    my ($filename) = @_;

    my @array;

    open( my $FILE, $filename ) or die "Cannot open file: $!\n";
    while (<$FILE>)
    {
        push( @array, $_ );
    }
    close($FILE);

    return @array;
}

sub getDateHour
{

    # receives an archive file name in the form of ..._20110101_120101.txt
    # returns two strings: 2011.01.01 and 12:01:01

    my ( $line ) = @_;    # receive args
#    my $dotPos = index( $line, '.' );    # get the position of the dot (there should only be one!)
#    my $usPos = rindex( $line, '_' );    # get the position of the last _ (multiple may exist)
#    my $hour = substr( $line, $usPos + 1, $dotPos - $usPos - 1 );    # get the hour
#    my $us2Pos = rindex( $line, '_', $usPos - 1 );    # get the position of the last but 1 _
#    my $day = substr( $line, $us2Pos + 1, $usPos - $us2Pos - 1 );    # get the day

    

    # split it up, insert the dots, join
#    my @a_day = split( //, $day );
#    splice( @a_day, 4, 0, '.' );
#    splice( @a_day, 7, 0, '.' );
#    $day = join( '', @a_day );

    # split it up, insert the colons, join
#    my @a_hour = split( //, $hour );
#    splice( @a_hour, 2, 0, ':' );
#    splice( @a_hour, 5, 0, ':' );
#    $hour = join( '', @a_hour );

    $line =~ m/_(\d\d\d\d)(\d\d)(\d\d)_(\d\d)(\d\d)(\d\d)\.txt/;

    # return formatted date and hour strings
#    return ( $day, $hour );

    return ( $1.'.'.$2.'.'.$3, $4.':'.$5.':'.$6 );

}

sub getEpoch
{

    # receives an archive file name in the form of ..._20110101_120101.txt
    # returns date/time in epoch format: 1293883261

    my ($line) = @_;    # receive args
    my $dotPos = index( $line, '.' );    # get the position of the dot
    my $usPos = rindex( $line, '_' );    # get the position of the last _
    my $time = substr( $line, $usPos + 1, $dotPos - $usPos - 1 );    # hhmmss
    my ( $hour, $min, $sec ) = unpack( 'a2 a2 a2', $time );
    my $us2Pos = rindex( $line, '_', $usPos - 1 );    # get the position of the last but 1 _
    my $date = substr( $line, $us2Pos + 1, $usPos - $us2Pos - 1 );    # yyyymmdd
    my ( $year, $month, $day ) = unpack( 'a4 a2 a2', $date );

    # months 0..11 (!)
    return my $epoch = timelocal( $sec, $min, $hour, $day, $month - 1, $year );
}

sub getReadableTime
{

    # receives elapsed time in seconds, eg. 1943
    # returns time in comma-separated human readable format: 32 minutes, 23 seconds
    # uses years, months, days, hours, minutes, and seconds if necessary
    # singular/plurar cases are handled

    my ($time) = @_;    # receive args (epoch time)

    my $years  = 0;
    my $months = 0;
    my $days   = 0;
    my $hours  = 0;
    my $mins   = 0;
    my $secs   = 0;
    my $ret    = "";
    my @outArray;

    if ( $time > (YEAR) )
    {
        $years = int( $time / (YEAR) );
        $time = $time % (YEAR);
    }
    if ( $time > (MONTH) )
    {
        $months = int( $time / (MONTH) );
        $time = $time % (MONTH);
    }
    if ( $time > (DAY) )
    {
        $days = int( $time / (DAY) );
        $time = $time % (DAY);
    }
    if ( $time > (HOUR) )
    {
        $hours = int( $time / (HOUR) );
        $time = $time % (HOUR);
    }
    if ( $time > MIN )
    {
        $mins = int( $time / MIN );
        $time = $time % MIN;
    }
    if ( $time > 0 )
    {
        $secs = $time;
    }

    my $word = "";
    if ( $years != 0 )
    {
        $word = "years";
        $word = "year" if ( $years == 1 );
        push( @outArray, $years . " $word" );
    }
    if ( $months != 0 )
    {
        $word = "months";
        $word = "month" if ( $months == 1 );
        push( @outArray, $months . " $word" );
    }
    if ( $days != 0 )
    {
        $word = "days";
        $word = "day" if ( $days == 1 );
        push( @outArray, $days . " $word" );
    }
    if ( $hours != 0 )
    {
        $word = "hours";
        $word = "hour" if ( $hours == 1 );
        push( @outArray, $hours . " $word" );
    }
    if ( $mins != 0 )
    {
        $word = "mins";
        $word = "min" if ( $mins == 1 );
        push( @outArray, $mins . " $word" );
    }
    if ( $secs != 0 )
    {
        $word = "secs";
        $word = "sec" if ( $secs == 1 );
        push( @outArray, $secs . " $word" );
    }
    $ret = join( ', ', @outArray );
    return $ret;
}

sub assembleStepSelector
{

    # receives stepSelector value: 1, 10, or 100
    # returns new stepSelector string

    my ($newStep) = @_;    # recieve args
    my $stepSelector;
    $stepSelector = "(1) 10  100 " if ( $newStep == 1 );
    $stepSelector = " 1 (10) 100 " if ( $newStep == 10 );
    $stepSelector = " 1  10 (100)" if ( $newStep == 100 );
    return $stepSelector;
}

sub printControlHeader
{

    # receives NONE
    # prints formatted control header
    # returns NONE

    my $cr = '';
    $cr = "\r" if ($archiverInited);
    $archiverInited = 1;
    my ( $currentDate, $currentHour ) = &getDateHour( $archFiles[$currentEntry - 1] );
    my $ce = sprintf( '%04d', $currentEntry );
    my $prt =
        $cr
      . "> #$ce $currentDate $currentHour "
      . &assembleStepSelector($currentStep)
      . " <- -> r q ? <";
    print $prt;
}

1;
