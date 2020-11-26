package Koha::Plugin::Com::BibLibre::LinkedData;

use base qw(Koha::Plugins::Base);

use Modern::Perl;

use Encode qw( decode_utf8 );
use File::Temp;

use C4::Auth;
use C4::Context;
use Koha::Libraries;

# TODO create a configuration page
our $import_script = '/home/koha/bdp/scripts/import.pl';
our $return_script = '/home/koha/bdp/scripts/nettoie_bdp.pl';

our $VERSION = '1.0';

our $metadata = {
    name            => 'BDP Import',
    author          => 'BibLibre',
    description     => 'BDP Import via scripts',
    date_authored   => '2020-09-01',
    date_updated    => '2020-09-01',
    minimum_version => '18.11',
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
    my $test = $query->param('test');
    my $branchcode = $query->param('branchcode');
    my ( $filename, $script_logs );

    if ( $op eq 'import' ) {
        $filename = $query->param('bdpfile');
        if ( -e $import_script) {

            my $upload_filehandle = $query->upload('bdpfile');
            my ( $tfh, $tempfile ) = File::Temp::tempfile( SUFFIX => '_import_bdp' );
            binmode $tfh;
            while (<$upload_filehandle>) {
                print $tfh $_;
            }

            my @command;
            push @command, $import_script;
            push @command, "-s";
            push @command, $branchcode;
            push @command, "-file";
            push @command, "$tempfile";
            push @command, "-t " if ($test);

            $script_logs = qx(@command);
            $script_logs =~ s/\n/<br \/>/g;

            close $tfh;
        }
        else {
            $script_logs = "Le script $import_script n'existe pas";
        }
    }
    elsif ( $op eq 'return' ) {
        $filename = $query->param('returnbdpfile');
        if ( -e $return_script) {
            my $upload_filehandle = $query->upload('returnbdpfile');
            my ( $tfh, $tempfile ) = File::Temp::tempfile( SUFFIX => '_return_bdp' );
            binmode $tfh;
            while (<$upload_filehandle>) {
                print $tfh $_;
            }

            my @command;
            push @command, $return_script;
            push @command, "-file";
            push @command, "$tempfile";
            push @command, "-b";
            push @command, C4::Context->userenv->{branch};
            push @command, "-t" if ($test);
            push @command, "-v";

            $script_logs = qx(@command);
            $script_logs =~ s/\n/<br \/>/g;

            close $tfh;
        }
        else {
            $script_logs = "Le script $return_script n'existe pas";
        }
    }

    $template->param(
        filename    => $filename,
        op          => $op,
        script_logs => Encode::decode_utf8($script_logs),
    );

    return $self->output_html( $template->output() );
}

1;
