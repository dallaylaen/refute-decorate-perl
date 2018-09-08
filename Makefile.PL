use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Assert::Refute::DbC',
    AUTHOR           => q{Konstantin S. Uvarin <khedin@gmail.com>},
    VERSION_FROM     => 'lib/Assert/Refute/DbC.pm',
    ABSTRACT_FROM    => 'lib/Assert/Refute/DbC.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
        'Test::Deep' => 1.04,
    },
    PREREQ_PM => {
        'Assert::Refute' => 0.14,
        'Moo' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Assert-Refute-DbC-*' },
);
