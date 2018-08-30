use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Assert::Refute::Decorate',
    AUTHOR           => q{Konstantin S. Uvarin <khedin@gmail.com>},
    VERSION_FROM     => 'lib/Assert/Refute/Decorate.pm',
    ABSTRACT_FROM    => 'lib/Assert/Refute/Decorate.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Test::Deep' => 1.04,
        'Assert::Refute' => 0.13,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Assert-Refute-Decorate-*' },
);
