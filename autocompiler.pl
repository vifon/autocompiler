#!/usr/bin/env perl
#########################################################################
# Copyright (C) 2012  Wojciech Siewierski                               #
#                                                                       #
# This program is free software: you can redistribute it and/or modify  #
# it under the terms of the GNU General Public License as published by  #
# the Free Software Foundation, either version 3 of the License, or     #
# (at your option) any later version.                                   #
#                                                                       #
# This program is distributed in the hope that it will be useful,       #
# but WITHOUT ANY WARRANTY; without even the implied warranty of        #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
# GNU General Public License for more details.                          #
#                                                                       #
# You should have received a copy of the GNU General Public License     #
# along with this program.  If not, see <http://www.gnu.org/licenses/>. #
#########################################################################

use warnings;
use strict;
use 5.010;

use Linux::Inotify2;
use Term::ReadKey;
use Pod::Usage;
use Getopt::Long;
Getopt::Long::Configure(qw(
                              bundling
                              no_ignore_case
                              no_auto_abbrev
                              auto_version
                         ));

my $separate = 1;
my $directory;

=head1 OPTIONS

=over 4

=item B<--separate>, B<--sep>, B<-s>

Draw the lines separating compilations.

=item B<--dir> I<directory>, B<-d> I<directory>

Directory to scan.

=back

=cut

GetOptions(
           "separate|sep|s!" => \$separate,
           "dir|d=s"         => \$directory,
           "help|h"          => sub { pod2usage {-verbose => 2} },
          ) or die pod2usage {
              -verbose => 2,
          };

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
        # FIXME
        # I don't know why but the events are generated twice so I ignore the even ones
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
