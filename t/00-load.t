#!/usr/bin/perl

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;

use t::lib::TestBuilder;
use Test::More;
use File::Spec;
use File::Find;
use CGI;
use XML::LibXML;

use Koha::Plugin::Com::BibLibre::LinkedData;

=head1 DESCRIPTION
=cut

my $builder = t::lib::TestBuilder->new();

my $lib = '/home/koha/lib/koha-plugin-linked-data/'; # Could be changed to $Bin/..

unshift( @INC, $lib );
unshift( @INC, '/home/koha/src/' );
unshift( @INC, '/home/koha/src/misc/translator/' );
unshift( @INC, '/home/koha/src/t/lib/' );

find(
    {
        bydepth  => 1,
        no_chdir => 1,
        wanted   => sub {
            my $m = $_;
            return unless $m =~ s/[.]pm$//;
            $m =~ s{^.*/Koha/}{Koha/};
            $m =~ s{/}{::}g;
            use_ok($m) || BAIL_OUT("***** PROBLEMS LOADING FILE '$m'");
        },
    },
    $lib
);

my $record = MARC::Record->new();
$record->append_fields(
        MARC::Field->new( '033', ' ', ' ', 'a' => 'ark:/12148/cb15037560d' ),
    );  

    $record->append_fields(
        MARC::Field->new( '200', ' ', ' ', 'a' => 'Harry Potdbeurre' ),
    );  

    my ($biblio_id) = C4::Biblio::AddBiblio( $record, '');
    #TODO: test instanciation plugin
    intranet_catalog_biblio_tab
done_testing();
