#! /usr/bin/env perl
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'BTLib',
    'VERSION_FROM'	=> 'BTLib.pm', # finds $VERSION
    'AUTHOR'		=> 'Christian Iseli',
    'EXE_FILES'		=> [ 'fetch', 'indexer', 'netfetch' ]
);
