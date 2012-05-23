#!/usr/bin/env perl

use warnings;
use strict;
use 5.010;

use Linux::Inotify2;
use Term::ReadKey;
use Getopt::Long;
Getopt::Long::Configure(qw(
                              bundling
                              no_ignore_case
                              no_auto_abbrev
                              auto_version
                         ));

my $separate = 1;
my $directory;

GetOptions(
           "separate|sep|s!" => \$separate,
           "dir|d=s"         => \$directory,
          ) or die "\n";

my @args = @ARGV;

unless (defined $directory) {
    if (-d "./src") {
        $directory = "./src"
    } else {
        $directory = "."
    }
}

my $inotify = new Linux::Inotify2;
$inotify->watch($_, IN_MODIFY, createCompileClosure()) while <$directory/*.c $directory/*.h $directory/*.cpp $directory/*.hpp>;

$inotify->poll while 1;


sub createCompileClosure {
    my %ignore;
    return sub {
        my $event = shift;
        if (exists $ignore{$event->fullname}) {
            delete $ignore{$event->fullname};
        } else {
            if ($separate) {
                my ($cols) = GetTerminalSize();
                say "-" x $cols;
            }
            say "make @args";
            system("make @args");
            $ignore{$event->fullname} = 1;
        }
    };
}