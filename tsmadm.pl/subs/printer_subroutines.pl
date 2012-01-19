#!/usr/bin/perl

use strict;
use warnings;

use List::Util qw(sum);

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

my %Separators;

# init text printer
&setSimpleTXTOutput;

=encoding utf-8

=head1 NÉV/NAME

setVALAMIOutput - beállítja a mező és rekord szeparátorokat, az I<universalTextPrinter> számára

=head2 SYNOPSIS/SZINTAXIS

        &setSimpleTXTOutput();
        &universalTextPrinter( "KEY\tREGEXP\tVALUE", @array );


 
=head2 DESCREPTION/LEÍRÁS

A szubrutin a %Separators nevű hash-t tölti fel következő elemekkel:

        Iam              => Jeleneleg nem használt, pl.: "HTML", 
        startTable       => A táblázat indító eleme, pl.: "<table>\n", 
        stopTable        => A táblázat záró elemem, pl.: "</table>\n",
        startHeaderLine  => A fejléc sorainak indító eleme, pl.: "<tr>",
        stopHeaderLine   => A fejléc sorainak záró eleme, pl.: "</tr>\n",
        startHeaderField => A fejléc mezőinek indító eleme, pl.: "<th>",
        stopHeaderField  => A fejléc mezőinek záró eleme, pl.:"</th>",
        startField       => A táblázat mezőinek indító eleme, pl.: "<td>",
        stopField        => A táblázat mezőinek záró eleme, pl.: "</td>",
        startRecord      => A táblázat sorainak indító eleme, pl.: "<tr>",
        stopRecord       => A táblázat sorainak záró eleme, pl.: "</tr>\n",

=head2 AUTHOR/FEJLESZTŐ

Szabó Marcell

=head2 SEE ALSO/TOVÁBBI INFORMÁCIÓK

I<universalTextPrinter>

=cut

sub setHTMLOutput
{
    %Separators = (
                    Iam              => "HTML",
                    startTable       => "<table>\n",
                    stopTable        => "</table>\n",
                    startHeaderLine  => "<tr>",
                    stopHeaderLine   => "</tr>\n",
                    startHeaderField => "<th>",
                    stopHeaderField  => "</th>",
                    startField       => "<td>",
                    stopField        => "</td>",
                    startRecord      => "<tr>",
                    stopRecord       => "</tr>\n",
                  );
}

sub setCSVOutput
{

    %Separators = (
                    Iam              => "CSV-NOQUOTE",
                    startTable       => "",
                    stopTable        => "",
                    startHeaderLine  => "",
                    stopHeaderLine   => "\n",
                    startHeaderField => "",
                    stopHeaderField  => ";",
                    startField       => "",
                    stopField        => ";",
                    startRecord      => "",
                    stopRecord       => "\n",
                  )

}

sub setTXTOutput
{

    %Separators = (
                    Iam              => "TXT",
                    startTable       => "",
                    stopTable        => "",
                    startHeaderLine  => "|",
                    stopHeaderLine   => "\n",
                    startHeaderField => "",
                    stopHeaderField  => "|",
                    startField       => "",
                    stopField        => "|",
                    startRecord      => "|",
                    stopRecord       => "\n",
                  )

}

sub setSimpleTXTOutput
{

    %Separators = (
                    Iam              => "TXT",
                    startTable       => "",
                    stopTable        => "",
                    startHeaderLine  => "",
                    stopHeaderLine   => "\n",
                    startHeaderField => "",
                    stopHeaderField  => " ",
                    startField       => "",
                    stopField        => " ",
                    startRecord      => "",
                    stopRecord       => "\n",
                  );
}

sub setTestTXTOutput
{

    %Separators = (
                    Iam              => "TXT",
                    startTable       => "STAT",
                    stopTable        => "STOT",
                    startHeaderLine  => "STAH",
                    stopHeaderLine   => "STOH\n",
                    startHeaderField => "STAHF",
                    stopHeaderField  => "STOHF ",
                    startField       => "STAF",
                    stopField        => "STOF ",
                    startRecord      => "STAR",
                    stopRecord       => "STOR\n",
                  );
}

sub universalTextPrinter ( @ )
{
    if ( $ParameterRegExpValues{HTML} ) { &HTMLPrinter(@_); return }
    if ( $ParameterRegExpValues{CSV}  ) { &setCSVOutput; }
    my @result = @_;
    my $i      = 0;

    my $startTable       = $Separators{startTable};
    my $stopTable        = $Separators{stopTable};
    my $startHeaderLine  = $Separators{startHeaderLine};
    my $stopHeaderLine   = $Separators{stopHeaderLine};
    my $startHeaderField = $Separators{startHeaderField};
    my $stopHeaderField  = $Separators{stopHeaderField};
    my $startField       = $Separators{startField};
    my $stopField        = $Separators{stopField};
    my $startRecord      = $Separators{startRecord};
    my $stopRecord       = $Separators{stopRecord};

    my @fieldlength;
    my @fieldFormat;
    my @fieldColor;
    my @fieldHeader;
    my @fieldAlign;

    &updateTerminalSettings;

    # Header Reader
    my $j = 0;
    my @header = split( /\t/, $result[0] );
    splice( @result, 0, 1 );

    foreach my $field ( @header ) {
        my ( $format, $color, $header, $align );
        if ( $field =~ s/{\s*([^\}]*?)\s*}// )
        {
            $format = $1;
        }
        else
        {
            $format = "";
        }
        if ( $field =~ s/\[\s*([^\]]*?)\s*\]// )
        {
            $color = $1
        }
        else
        {
            $color = "";
        }
        $field =~ s/^\s*|\s*$//g;
        $header = $field;
        if (uc($format) =~ m/LEFT|RIGHT/ )
        {
            $align = $format;
            $format = "";
        }
        else
        {
            $align = "LEFT";
        }
        $fieldlength[$j] = &colorLength( $field );

        $fieldColor[$j]  = $color;
        $fieldHeader[$j] = $header;
        $fieldFormat[$j] = $format;
        $fieldAlign[$j]  = $align;
        
        $j++;
        
    }

    # Find longest fields
    foreach ( @result ) {
        chomp;

        $j = 0;
        foreach ( split( /\t/, $_ ) ) {

            if ( defined( $fieldFormat[$j] ) && $fieldFormat[$j] !~ m/MAX/ )
            {
                my $printableField = $_;
                $printableField = sprintf( $fieldFormat[$j], $_ )
                  if ( $fieldFormat[$j] ne "" );
                $fieldlength[$j] = &colorLength($printableField)
                  if ( $fieldlength[$j] < &colorLength($printableField) );
            }
            $j++;
        }
    }

    $j = 0;

    # Find the MAX in the format field
    foreach my $field (@fieldlength)
    {
        my $remained = $Settings{TERMINALCOLS} - sum(@fieldlength);
        my $max =
          $fieldlength[$j] +
          $remained -
          ( colorLength($startRecord) +
            colorLength($stopRecord) +
            $#header * &colorLength($startField) +
            $#header * &colorLength($stopField) +
            &colorLength($stopField) +
            &colorLength($stopRecord) +
            1 );
        if ( $fieldFormat[$j] =~ m/MAX/ && $max <= $fieldlength[$j] )
        {
            &msg("0017E");    ##Terminal width is too small!
            $max = 1;
        }

        if ( $fieldFormat[$j] =~ s/MAX/$max/g )
        {
            $fieldlength[$j] = $max;
        }
        $j++;

    }

    # A printelendö szöveg összeállítása
    my @toPrint;
    my $printableLine  = $startHeaderLine;
    my $printableField = "";
    my $header_line    = $startHeaderLine;

    $j = 0;
    #HEADER
    foreach (@fieldHeader)
    {
        chomp;
        $printableField = $_;

        if ( $fieldAlign[$j] ne "LEFT" )
        {
            $printableField = sprintf( "% " . (length( $printableField )+$fieldlength[$j]-&colorLength( $printableField ) ) . "s", "$printableField" );
        }
        else
        {
            $printableField = sprintf( "%-" . (length( $printableField )+$fieldlength[$j]-&colorLength( $printableField ) ) . "s", "$printableField" );
        }

        if ( $Settings{HEADERCOLOR} eq "" )
        {
            $Settings{HEADERCOLOR} = $fieldColor[$j];
        }

        $printableField = colorString( $printableField, $Settings{HEADERCOLOR} );
        $header_line .=
            $startHeaderField
          . colorString( "-" x $fieldlength[$j], $Settings{HEADERCOLOR} )
          . $stopHeaderField;
        $printableLine .= $startHeaderField . $printableField . $stopHeaderField;
        #print $printableLine;
        $j++;
    }

    # and finally add the lines around the header

      if ( "@fieldHeader" !~ m/NOHEADER/ ) {
        push( @toPrint, $startTable );
        push( @toPrint, $header_line . $stopHeaderLine);
        push( @toPrint, $printableLine . $stopHeaderLine);
        push( @toPrint, $header_line . $stopHeaderLine );
      }

    #BODY
    foreach ( &grepIt(@result) )
    {
        chomp;
        
        my @line = split( /\t/, $_ );
        my $j = 0;
        my $beforeLast      = "" ;
        my $beforeLastEmpty = "" ;
        my $last = "";
        $printableLine = "";
        foreach (@line)
        {
            $printableField = $_;

            $printableField = &globalHighlighter( $printableField );

            if ( defined ( $ParameterRegExpValues{PGREP} ) && $ParameterRegExpValues{PGREP} ne '' && $_ =~ m/$ParameterRegExpValues{PGREP}/ ) {
                $printableField = &printerGrepHighlighter ( $printableField, $ParameterRegExpValues{PGREP}, $Settings{HIGHLIGHTCOLOR} );
            }

            if ( defined ( $fieldAlign[$j] ) && $fieldAlign[$j] ne "LEFT" )
            {
                $printableField = sprintf( "% " . ( length( $printableField ) + $fieldlength[$j] - &colorLength( $printableField ) ) . "s", "$printableField" ) if ( defined( $fieldlength[$j] ) );
            }
            else
            {
                $printableField = sprintf( "%-" . ( length( $printableField ) + $fieldlength[$j] - &colorLength( $printableField ) ) . "s", "$printableField" ) if ( defined( $fieldlength[$j] ) );
            }

#			if ($printableField =~ m/$grep/ ) {$printableField = colorString($printableField,"RED");} ## whole line grep
#			if ($printableField =~ m/$grep/ ) {my $cgrep = colorString($grep,"RED") ;$printableField =~ s/$grep/$cgrep/;} ## highlighter GREP
            if (    defined( $ParameterRegExpValues{HIGHLIGHT} )
                 && $ParameterRegExpValues{HIGHLIGHT} ne ""
                 && $printableField =~ m/$ParameterRegExpValues{HIGHLIGHT}/ )
            {

                #				my $chighlighter = sprintf (colorString($1,"RED"));
                my $chighlighter =
                  &colorString( $ParameterRegExpValues{HIGHLIGHT}, $Settings{HIGHLIGHTCOLOR} );

                $printableField =~ s/$ParameterRegExpValues{HIGHLIGHT}/$chighlighter/;
            }    ## highlighter grep

            $printableField = &colorString( $printableField, $fieldColor[$j] );

            #print "hossz: ".length($printableField);
            $printableLine .= $startField . $printableField . $stopField;
            if ($j == $#line) { $last = $startField . $printableField . $stopField }
            $j++;
            if ($j == $#line) { $beforeLast = $printableLine };
            if ($j <= $#line) { $beforeLastEmpty .= $startField . sprintf( "%-" . &colorLength( $printableField ) . "s", "" ) . $stopField }
        }
        if ( &colorLength( $startRecord . $printableLine . $stopRecord ) > $Settings{TERMINALCOLS} && 1 )
        {        #Hosszu sorok szopasa
            $last =~ s/\s+$//;
            #print "BefLAST: [$beforeLast]\n";
            #print "LAST: [$last]\n";
            my $restLength = $Settings{TERMINALCOLS} -  ( $OS_win ? 1 : 0 ) - &colorLength($beforeLast.$startRecord.$stopRecord.$stopField);
            #my $printable = $beforeLast.substr( $last, 0, &colorSubstr( $last, $restLength )).$stopField.$stopRecord;
            my $rest = $last; #substr( $last, $restLength );
            my $currentPos = $restLength;
            #print "restLength: [$restLength]\n";

            my $inheritLastColor = "";

            #print $rest;
            #push( @toPrint, $startRecord . $printable . $stopRecord );
            my $c = 0;
            while ( 1 ) {

                #print $startRecord.$beforeLast.$startField.substr ($rest, 0, &colorSubstr($rest, $restLength)).$stopField.$stopRecord;
                #print "length: ".&colorLength($rest)."[".$rest."]"."\n";

                if ( $c == 0 ) {
                	$c++;
                }
                else {
                    $beforeLast = $beforeLastEmpty;
                }

                if ( &colorLength( $rest ) < $restLength ) {
                	push( @toPrint, $startRecord.$beforeLast.$startField.$inheritLastColor.substr( $rest, 0, &colorSubstr( $rest, &colorLength($rest) ) ).&colorString( "", "RESET" ).$stopRecord );
                	last;
                }
                else {
                    push( @toPrint, $startRecord.$beforeLast.$startField.$inheritLastColor.substr( $rest, 0, &colorSubstr( $rest, $restLength ) ).&colorString( "", "RESET" ).$stopField.$stopRecord );
                    my $tmp = substr( $rest, 0, &colorSubstr( $rest, $restLength ) );
                    $inheritLastColor = $1 if ( $tmp =~ s/(\e\[\d+?;*\d*m)//g );
                }

                $rest = substr( $rest, &colorSubstr( $rest, $restLength ) );
                last if ( &colorLength( $rest ) == 0 ); # skip empty lines

           }
           } else {
               push( @toPrint, $startRecord . $printableLine . $stopRecord );
           }
        #print $printableLine."\n";
        #print @toPrint;
        #exit;
    }
    push( @toPrint, $stopTable );

    ### Printing to the screen
    my $more = 1;    ## MORE
    foreach (@toPrint)
    {
        if (&colorLength($_) > ( $Settings{TERMINALCOLS}) ) {
            print substr( $_, 0, &colorSubstr( $_, $Settings{TERMINALCOLS} - &colorLength( $stopField.$stopRecord ) - ( $OS_win ? 1 : 0 ) )).$stopField.$stopRecord.&colorString( "", "RESET" );
        } else {
            print $_;
        }
        if (    $ParameterRegExpValues{MORE}
             && $Settings{TERMINALROWS} - 2 <= $more )
        {
            print "more...   (<ENTER> to continue, 'C' to cancel)";
            last if ( <STDIN> =~ m/c/i );
            $more = 0;
        }
        $more++;
    }
    ### Printing to a file if needed
    if ( defined( $ParameterRegExpValues{OUTPUT} )
         && $ParameterRegExpValues{OUTPUT} ne "" )
    {
        open my $OUTFILE, ">$ParameterRegExpValues{OUTPUT}" or die;
        print $OUTFILE @toPrint;
        close $OUTFILE or die;
    }
    if ( defined( $ParameterRegExpValues{MAIL} )
         && $ParameterRegExpValues{MAIL} ne "" )
    {
        &sendMail( $ParameterRegExpValues{MAIL}, @toPrint );
    }

    # reset the settings
    &setSimpleTXTOutput();
    $Settings{'DISABLEGREP'} = 0;
#    print &colorString( '', 'RESET' );

}

sub HTMLPrinter ( @ )
{    #
    &setHTMLOutput;
    $ParameterRegExpValues{NOCOLOR} = 1;
    my @result = @_;

    my $startTable       = $Separators{startTable};
    my $stopTable        = $Separators{stopTable};
    my $startHeaderLine  = $Separators{startHeaderLine};
    my $stopHeaderLine   = $Separators{stopHeaderLine};
    my $startHeaderField = $Separators{startHeaderField};
    my $stopHeaderField  = $Separators{stopHeaderField};
    my $startField       = $Separators{startField};
    my $stopField        = $Separators{stopField};
    my $startRecord      = $Separators{startRecord};
    my $stopRecord       = $Separators{stopRecord};

    my @fieldColor;
    my @fieldHeader;

    # Header Reader
    my $j = 0;
    my @header = split( /\t/, $result[0] );
    splice( @result, 0, 1 );

    foreach my $field (@header)
    {    #text  =~ s/\[\s*([^\]]*?)\s*\]//;
        my ( $format, $color, $header );
        if   ( $field =~ s/{\s*([^\}]*?)\s*}// ) { $format = $1; }
        if   ( $field =~ s/\[\s*([^\]]*?)\s*\]// ) { $color = $1 }
        else                                       { $color = ""; }
        $field =~ s/^\s*|\s*$//g;
        $header = $field;

        $fieldColor[$j]  = $color;     #print "$j.oszlop szin:   $fieldColor[$j]\n";
        $fieldHeader[$j] = $header;    #print "$j.oszlop header: $yfieldHeader[$j]\n";
        $j++;
    }

    # A printelendö szöveg összeállítása
    my @toPrint;
    my $printableLine  = $startHeaderLine;
    my $printableField = "";
    my $header_line    = $startHeaderLine;

    $j = 0;

    #HEADER
    foreach (@fieldHeader)
    {
        chomp;
        $printableField = $_;

        if ( $Settings{HEADERCOLOR} eq "" )
        {
            $Settings{HEADERCOLOR} = $fieldColor[$j];
        }
        $printableField = &colorHTMLtag( $printableField, $Settings{HEADERCOLOR} );
        $header_line .= "";    #$startHeaderField$stopHeaderField ;
        $printableLine .= $startHeaderField . $printableField . $stopHeaderField;

        $j++;
    }

    # and finally add the lines around the header
    push( @toPrint, $startTable );

#push ( @toPrint, $header_line.$stopHeaderLine.$printableLine.$stopHeaderLine.$header_line.$stopHeaderLine ) if ( "@fieldHeader" !~ m/NOHEADER/ );
    push( @toPrint, $printableLine . $stopHeaderLine )
      if ( "@fieldHeader" !~ m/NOHEADER/ );

#BODY
#	@result = grep(/$ParameterRegExpValues{GREP}/i, @result)  if  (defined ($ParameterRegExpValues{GREP}) && $ParameterRegExpValues{GREP} ne "" && $Settings{'DISABLEGREP'} eq 'OFF'); ## Grep
#	@result = grep(!/$ParameterRegExpValues{INVGREP}/i, @result)  if  (defined ($ParameterRegExpValues{INVGREP}) && $ParameterRegExpValues{INVGREP} ne "" && $Settings{'DISABLEGREP'} eq 'OFF'); ## INVGrep
    foreach (@result)
    {
        chomp;
        my @line = split( /\t/, $_ );
        my $j = 0;
        $printableLine = "";
        foreach (@line)
        {
            $printableField = $_;

            if (    defined( $ParameterRegExpValues{HIGHLIGHT} )
                 && $ParameterRegExpValues{HIGHLIGHT} ne ""
                 && $printableField =~ m/$ParameterRegExpValues{HIGHLIGHT}/ )
            {
                my $chighlighter =
                  &colorHTMLtag( $ParameterRegExpValues{HIGHLIGHT}, $Settings{HIGHLIGHTCOLOR} );
                $printableField =~ s/$ParameterRegExpValues{HIGHLIGHT}/$chighlighter/;
            }    ## highlighter grep

            $printableField = &colorHTMLtag( $printableField, $fieldColor[$j] );

            #print "hossz: ".length($printableField);
            $printableLine .= $startField . $printableField . $stopField;
            $j++;
        }
        push( @toPrint, $startRecord . $printableLine . $stopRecord );
    }
    push( @toPrint, $stopTable );

    ### Printing to the screen
    foreach (@toPrint)
    {
        print $_;
    }
    ### Printing to a file if needed
    if ( defined( $ParameterRegExpValues{OUTPUT} )
         && $ParameterRegExpValues{OUTPUT} ne "" )
    {
        open my $OUTFILE, ">$ParameterRegExpValues{OUTPUT}" or die;
        print $OUTFILE @toPrint;
        close $OUTFILE or die;
    }

#	if (defined ($ParameterRegExpValues{MAIL}) && $ParameterRegExpValues{MAIL} ne "") {&sendMail($ParameterRegExpValues{MAIL},@toPrint);}

}

1;
