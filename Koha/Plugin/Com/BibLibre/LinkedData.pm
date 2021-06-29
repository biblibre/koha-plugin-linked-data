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
    my ($self, $simple_ark_id) = @_;
    return "" unless $simple_ark_id; 
    # https://w.wiki/oJi
    my $endpoint = "https://query.wikidata.org/bigdata/namespace/wdq/sparql";


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
      FILTER(CONTAINS(?idbnf, "$simple_ark_id"))
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

sub get_set_in_period {
    my ($self, $simple_ark_id) = @_;
    my $endpoint = "https://query.wikidata.org/bigdata/namespace/wdq/sparql";
    my $rdfquery = RDF::Query::Client->new(qq/
      SELECT ?setinperiod  ?setinperiodLabel
       WHERE {
       ?wdwork wdt:P268 ?idbnf.
       FILTER(CONTAINS(?idbnf, "$simple_ark_id"))
       OPTIONAL { ?wdwork wdt:P2408 ?setinperiod. }
       SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],  en". }  
      }/);
    my $set_in_period;      
    my $iterator = $rdfquery->execute($endpoint);
    while (my $row = $iterator->next) {
	my $uri_value = $row->{setinperiod}->uri_value;
        $set_in_period->{ $uri_value } = $row->{setinperiodLabel}->value;
    }
    return $set_in_period;
}


sub get_part_of_series {
    my ($self, $simple_ark_id) = @_;
    my $endpoint = "https://query.wikidata.org/bigdata/namespace/wdq/sparql";
    my $rdfquery = RDF::Query::Client->new(qq/
      SELECT ?partoftheserie ?partoftheserieLabel ?follows ?followsLabel ?followedby ?followedbyLabel       
      WHERE {                                                                                                              
        ?wdwork wdt:P268 ?idbnf.                                                                                                 
        FILTER(CONTAINS(?idbnf, "$simple_ark_id"))  
        OPTIONAL { ?wdwork wdt:P179 ?partoftheserie . } 
        OPTIONAL { ?wdwork wdt:P155 ?follows . } 
        OPTIONAL { ?wdwork wdt:P156 ?followedby . }  
        SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],  en". }  
     }/);
    # FIXME / NEXT: refacto de la structure de renvoi et affichage dans le template
    # NEXT: tests et refacto
    # NOTE: les données wikidata ne sont pas complètes sur les séries et le followedby n'est jamais renseigné (?)
    my $part_of_series;      
    my $iterator = $rdfquery->execute($endpoint);
    while (my $row = $iterator->next) {
        $part_of_series->{ "partoftheserie"} = $row->{partoftheserie}->value;
        $part_of_series->{ "partoftheserieLabel"} = $row->{partoftheserieLabel}->value;
        $part_of_series->{ "follows"} = $row->{follows}->value;
        $part_of_series->{ "followsLabel"} = $row->{followsLabel}->value;
        $part_of_series->{ "followedby"} = $row->{followedby}->value;
        $part_of_series->{ "followedbyLabel"} = $row->{followedbyLabel}->value;
    }
    return $part_of_series;


}

sub ark_id_to_simple_ark_id {
    my ($self, $ark_id) = @_;
    $ark_id =~ /.*cb(.*)$/;
    return $1;
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
    my $simple_ark_id = $self->ark_id_to_simple_ark_id($ark_id);
    my $narrative_locations = $self->get_wikidata_for_biblio($simple_ark_id);
    my $set_in_period_dates = $self->get_set_in_period($simple_ark_id);

    my $tmpl_content = "<h3>Contexte de Lecture:</h3><ul>";


    $tmpl_content .= "<li>Les lieux de l'action sont: ";
    foreach my $narrative_location (keys %$narrative_locations) {
        $tmpl_content .= "<a href=\"" . $narrative_location . "\">". $narrative_locations->{$narrative_location} . "</a> ";
    }
    $tmpl_content .= "</li>";

    $tmpl_content .= "<li>A l'epoque: "; 
    foreach my $set_in_period_date (keys %$set_in_period_dates) {
        $tmpl_content .= $set_in_period_dates->{$set_in_period_date} . " ";
    }
    $tmpl_content .= "</li>";


    $tmpl_content .= "</ul>";

    push @tabs, Koha::Plugins::Tab->new( {title => 'LRM', content => $tmpl_content});

    return @tabs;                                                                                                                                           
}                                                                                                                                                           
   
1;
