package Koha::Plugin::Com::BibLibre::LinkedData;

use base qw(Koha::Plugins::Base);

use Modern::Perl;
use RDF::Query::Client; 
use Data::Dumper;
use CGI qw ( -utf8 );

use C4::Context;
use Koha::Plugins::Tab;
use Koha::Biblios;


our $VERSION = '0.1';

our $metadata = {
    name            => 'Linked data',
    author          => 'BibLibre',
    description     => 'Linked data',
    date_authored   => '2020-11-26',
    date_updated    => '2020-11-26',
    minimum_version => '19.11',
    maximum_version => undef,
    version         => $VERSION,
};

sub new {
    my ( $class, $args ) = @_;

    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    my $self = $class->SUPER::new($args);
    $self->{cgi} = CGI->new;
    return $self;
}

# Mandatory even if does nothing
sub install {
    my ( $self, $args ) = @_;

    return 1;
}

# Mandatory even if does nothing
sub upgrade {
    my ( $self, $args ) = @_;

    return 1;
}

# Mandatory even if does nothing
sub uninstall {
    my ( $self, $args ) = @_;

    return 1;
}

# Do the job
sub tool {
    my ( $self, $args ) = @_;

    my $template = $self->get_template({ file => 'tmpl/home.tt' });
    my $query = $self->{'cgi'};

    my $op = $query->param('op') || '';

    $template->param(
        op          => $op,
    );

    return $self->output_html( $template->output() );
}

sub get_ark_id_for_biblio {
    my ($self, $biblionumber) = @_;

    return '' unless $biblionumber;

    my $record = Koha::Biblios->find($biblionumber);
    return '' unless $record;

    my $marc_record = $record->metadata->record;
    my $ark_id = $marc_record->subfield('033','a');

    return $ark_id;
}

sub get_wikidata_for_biblio {
    my ($self, $ark_id) = @_;
    return "" unless $ark_id; 
    # https://w.wiki/oJi
    my $endpoint = "https://query.wikidata.org/bigdata/namespace/wdq/sparql";

    $ark_id =~ /.*cb(.*)$/;
    my $wk_id = $1;

    #my $rdfquery = RDF::Query::Client->new(qq/
    #  SELECT ?wdwork ?narrative_location_id ?narrative_location WHERE {
    #  ?wdwork wdt:P268 ?idbnf.
    #  FILTER(CONTAINS(?idbnf, "$wk_id"))
    #  OPTIONAL { ?narrative_location_id wdt:P840 ?lieu. }
    #  OPTIONAL { ?narrative_location_id wdt:P1476 ?narrative_location. }
    #  SERVICE wikibase:label { bd:serviceParam wikibase:language "fr". }
    #  } 
    #  ORDER BY DESC(?narrative_location)
    #  LIMIT 5/);

    my $rdfquery = RDF::Query::Client->new(qq/
      SELECT ?narrativelocation ?narrativelocationLabel
      WHERE {
      ?wdwork wdt:P268 ?idbnf.
      FILTER(CONTAINS(?idbnf, "$wk_id"))
      OPTIONAL { ?wdwork wdt:P840 ?narrativelocation. }
      SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
      }/);

    my $narrative_locations;

    my $iterator = $rdfquery->execute($endpoint);
    while (my $row = $iterator->next) {
#warn Data::Dumper::Dumper ($row);
	my $uri_value = $row->{narrativelocation}->uri_value;
        $narrative_locations->{ $uri_value } = $row->{narrativelocationLabel}->value;
    }
    return $narrative_locations;

}


sub intranet_catalog_biblio_tab {                                                                                                                           
    my ( $self, $args ) = @_;
    my @tabs;                                                                                                                                               
    my $query = $self->{'cgi'};
    my $biblionumber = $query->param('biblionumber');
    my $endpoint = "https://query.wikidata.org/bigdata/namespace/wdq/sparql";
    my $ark_id = $self->get_ark_id_for_biblio($biblionumber);

    return @tabs unless $biblionumber;

    return @tabs unless $ark_id;

    my $rdfquery = RDF::Query::Client->new(qq/SELECT ?wdwork WHERE { ?wdwork wdt:P268 ?idbnf FILTER CONTAINS(?idbnf, "$ark_id") . }/);
    my $iterator = $rdfquery->execute($endpoint);

    my @rdf_data;
    push @tabs, Koha::Plugins::Tab->new( {title => 'ARK-ID', content => $ark_id});
    while (my $row = $iterator->next) {
      push @tabs,
      Koha::Plugins::Tab->new(                                                                                                                              
        {                                                                                                                                                   
            title   => 'WikiData',                                                                                                                            
            content => $row->{s}->as_string
        }                                                                                                                                                   
      );                                                                                                                                                    
    }

                                                                                                                                                            
    push @tabs,                                                                                                                                             
      Koha::Plugins::Tab->new(                                                                                                                              
        {                                                                                                                                                   
            title   => 'Tab 2',                                                                                                                             
            content => 'This is content for tab 2'                                                                                                          
        }                                                                                                                                                   
      );                                                                                                                                                    
                                                                                                                                                            
    return @tabs;                                                                                                                                           
}                                                                                                                                                           
   
1;
