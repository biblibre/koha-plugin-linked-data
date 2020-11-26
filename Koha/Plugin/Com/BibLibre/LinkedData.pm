package Koha::Plugin::Com::BibLibre::LinkedData;

use base qw(Koha::Plugins::Base);

use Modern::Perl;
use RDF::Query::Client; 

use C4::Context;
use Koha::Plugins::Tab;


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

sub intranet_catalog_biblio_tab {                                                                                                                           
    my @tabs;                                                                                                                                               
    push @tabs,                                                                                                                                             
      Koha::Plugins::Tab->new(                                                                                                                              
        {                                                                                                                                                   
            title   => 'WikiData',                                                                                                                            
            content => 'This is content for tab 1'                                                                                                          
        }                                                                                                                                                   
      );                                                                                                                                                    
                                                                                                                                                            
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
