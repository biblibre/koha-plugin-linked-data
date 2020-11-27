use Modern::Perl;

use Test::More;
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

#my $biblio = $builder->build_sample_biblio();
#warn Data::Dumper::Dumper($biblio->biblionumber);

    my $record = MARC::Record->new();
    my ( $tag, $subfield ) = $marcflavour eq 'UNIMARC' ? ( 200, 'a' ) : ( 245, 'a' );
    $record->append_fields(
        MARC::Field->new( $tag, ' ', ' ', $subfield => $title ),
    );  

    ( $tag, $subfield ) = $marcflavour eq 'UNIMARC' ? ( 200, 'f' ) : ( 100, 'a' );
    $record->append_fields(
        MARC::Field->new( $tag, ' ', ' ', $subfield => $author ),
    );  

    ( $tag, $subfield ) = $marcflavour eq 'UNIMARC' ? ( 995, 'r' ) : ( 942, 'c' );
    $record->append_fields(
        MARC::Field->new( $tag, ' ', ' ', $subfield => $itemtype )
    );  

    my ($biblio_id) = C4::Biblio::AddBiblio( $record, $frameworkcode );
done_testing();
