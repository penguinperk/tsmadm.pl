#!/usr/bin/perl

use strict;
use warnings;

&msg( '0110D', 'Aliases' );

&defineAlias( 'up',  '!svn up' );
&defineAlias( 'com', '!svn commit -m' );

&defineAlias( 'b',  'set server b' );
&defineAlias( 'w',  'set server w' );
&defineAlias( 'f',  'set server f' );
&defineAlias( 'h',  'set server h' );

1;