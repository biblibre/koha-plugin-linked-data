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
use Test::MockModule;

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

##mocker le return param de CGI 
my $cgi_mock = Test::MockModule->new('CGI');
$cgi_mock->mock(
    param => sub {
            return $biblio_id;
    }   
);

my $rdf_mock = Test::MockModule->new('RDF::Query::Client');
$rdf_mock->mock(
    execute => sub {
            return 'toto';
    }   
);

#TODO: test instanciation plugin
my $plugin = Koha::Plugin::Com::BibLibre::LinkedData->new;
ok $plugin;

my @table = $plugin->intranet_catalog_biblio_tab;
is(ref $table[0],'Koha::Plugins::Tab');

is($plugin->get_ark_id_for_biblio($biblio_id),'ark:/12148/cb15037560d');

# RDF::Trine::Iterator
is($plugin->get_wikidata_for_biblio($biblio_id), 'toto');

































done_testing();
