use Test::More;

use strict;
use warnings;

use Mojolicious::Plugin::PrettyConfig;

BEGIN {
    no warnings qw(redefine);
    *Mojolicious::Plugin::PrettyConfig::register = sub { };
}

my $plugin = Mojolicious::Plugin::PrettyConfig->new;
my $app    = App->new;
$plugin->_process_config(
    $app,
    {
        app => [
            k1 => [
                k3 => 1,
                k2 => 2,
            ],
            k4 => [ 4, 3 ],
            k5 => {
                k7 => [ \'(2*4)', 7, 6 ],
                k6 => 5,
                k9 => sub { 2**2 + 6 },
                k8 => \'(4+5)',
            },
        ]
    },
    {
        pretty_cfg_code   => 1,
        pretty_cfg_scalar => 1,
    }
);

is_deeply(
    $app,
    {
        k1 => [    { k3 => 1 }, { k2 => 2 }, ],
        k4 => [ 4, 3 ],
        k5 => [ { k6 => 5 }, { k7 => [ 8, 7, 6 ] }, { k8 => 9 }, { k9 => 10 }, ]
    },
    'ok'
);

done_testing();

package App {

    sub new {
        return bless {}, __PACKAGE__;
    }

    sub k1 {
        my $self = shift;
        $self->{k1} //= [];
        return $self;
    }

    sub k2 {
        my $self = shift;
        push( @{ $self->{k1} }, { k2 => shift } );
    }

    sub k3 {
        my $self = shift;
        push( @{ $self->{k1} }, { k3 => shift } );
    }

    sub k4 {
        my $self = shift;
        $self->{k4} //= [];
        push( @{ $self->{k4} }, shift );
    }

    sub k5 {
        my $self = shift;
        $self->{k5} //= [];
        return $self;
    }

    sub k6 {
        my $self = shift;
        push( @{ $self->{k5} }, { k6 => shift } );
    }

    sub k7 {
        my $self = shift;
        my $k7;
        for ( @{ $self->{k5} } ) {
            $k7 = $_->{k7} and last
                if exists $_->{k7};
        }

        if ( !$k7 ) {
            $k7 = [];
            push( @{ $self->{k5} }, { k7 => $k7 } );
        }
        push( @{$k7}, shift );
    }

    sub k8 {
        my $self = shift;
        push( @{ $self->{k5} }, { k8 => shift } );
    }

    sub k9 {
        my $self = shift;
        push( @{ $self->{k5} }, { k9 => shift } );
    }
};
