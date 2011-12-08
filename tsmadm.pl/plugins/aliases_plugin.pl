#!/usr/bin/perl

use strict;
use warnings;

&msg( '0110D', 'Predefined Aliases' );

&defineAlias( 'acte',  'sh act | grep anr\d\d\d\de' );
&defineAlias( 'actw',  'sh act | grep anr\d\d\d\dw' );

1;