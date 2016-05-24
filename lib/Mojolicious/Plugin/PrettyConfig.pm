package Mojolicious::Plugin::PrettyConfig;

# ABSTRACT: Easy setup your app via config

use mro;
use Mojo::Base 'Mojolicious::Plugin::Config';

sub register {
    my ( $self, $app, $conf ) = @_;

    my $config = $self->next::method( $app, $conf );

    $self->_process_config( $app, $config, $conf );
}

my %ref_types = (
    _DEFAULT => sub {
        my ( $self, $app, $applicator, $config, $key ) = @_;

        die 'Empty key to set on applicator!' unless $key;
        $applicator->$key($config);
    },

    ARRAY => sub {
        my ( $self, $app, $applicator, $config, $key ) = @_;

        # Default behaviour - like ordered hash when number of elements is even
        my $act_like_ordered_hash = !( @$config % 2 );

        if ($act_like_ordered_hash) {

            # Check if default behaviour is possible
            # check if each $key is applicator has method with name $key
            my %hash = @$config;
            for my $k ( keys %hash ) {
                if ( ref($k) || !$applicator->can($k) ) {
                    $act_like_ordered_hash = 0;
                    last;
                }
            }
        }

        if ($act_like_ordered_hash) {
            for ( my $i = 0; $i < @$config; $i += 2 ) {
                $self->_set_values(
                    $app,
                    (
                        $key
                        ? scalar( $applicator->$key )
                        : $applicator
                    ),
                    $config->[ $i + 1 ],
                    $config->[$i]
                );
            }
        }
        else {
            for my $value (@$config) {
                $self->_set_values( $app, $applicator, $value, $key );
            }
        }
    },

    HASH => sub {
        my ( $self, $app, $applicator, $config, $key ) = @_;

        for my $k ( sort keys %$config ) {
            $self->_set_values(
                $app,
                (
                    $key
                    ? scalar( $applicator->$key )
                    : $applicator
                ),
                $config->{$k},
                $k
            );
        }
    },

    SCALAR => sub {
        my ( $self, $app, $applicator, $config, $key ) = @_;

        $applicator->$key( eval($$config) );
    },

    CODE => sub {
        my ( $self, $app, $applicator, $config, $key ) = @_;

        $applicator->$key( $config->($app) );
    },

    REF => sub {
        my ( $self, $app, $applicator, $config, $key ) = @_;

        $applicator->$key($$config);
    },
);

sub _process_config {
    my ( $self, $app, $config, $conf ) = @_;

    return unless exists $config->{app};

    delete $ref_types{CODE}   unless $conf->{pretty_cfg_code};
    delete $ref_types{SCALAR} unless $conf->{pretty_cfg_scalar};

    $self->_set_values( $app, $app, $config->{app} );
}

sub _config_setter {
    my ( $self, $type, $sub ) = @_;

    $ref_types{$type} = $sub if $sub;

    return exists $ref_types{$type} ? $ref_types{$type} : $ref_types{_DEFAULT};
}

sub _set_values {
    my ( $self, $app, $applicator, $config, $key ) = @_;

    $self->_config_setter( ref $config )
        ->( $self, $app, $applicator, $config, $key );
}


1;

__END__

=head1 SYNOPSYS

    # Mojolicious
    $self->plugin(
        PrettyConfig => {
            pretty_cfg_code   => 1,
            pretty_cfg_scalar => 1,
        }
    );

    # Mojolicious::Lite
    plugin PrettyConfig => {
        pretty_cfg_code   => 1,
        pretty_cfg_scalar => 1,
    };

    # In your config
    app => [
        secrets  => \[ 'mySecret', 'myOldSecret' ],
        sessions => {
            default_expiration => 1800,
            cookie_name        => 'appSession',
        },
        routes => {
            get => [
                \" '/foo' => { controller => 'controller', action => 'do_foo' } => 'foo_action' ",
                sub {
                    '/boo'
                        => { controller => 'controller', action => 'do_boo' }
                        => 'boo_action'
                },
            ]
        }
    ]

    # Which will be resolved into
    $app->secrets( [ 'mySecret', 'myOldSecret' ] );
    $app->sessions->cookie_name('appSession');
    $app->sessions->default_expiration(1800);
    $app->routes->get(
        '/foo'
            =>  {
                    controller => 'controller',
                    action     => 'do_foo'
                }
            => 'foo_action'
    );
    $app->routes->get(
        '/boo'
            =>  {
                    controller => 'controller',
                    action     => 'do_boo'
                }
            => 'boo_action'
    );

=head1 DESCRIPTION

Configure application via config.
Use C<app> key in config file to configure your application.

There are some ref types to manage configuring flow.

=attr HASH

For each key will perform applicator configuring on key (note about B<sorting>):

    app => {
        sessions => {
            default_expiration => 1800,
            cookie_name => 'cookieName'
        }
    }

    # Will do (note about sorting):
    $app->sessions->cookie_name('cookieName');
    $app->sessions->default_expiration(1800);

=attr ARRAY

Use ARRAY like ordered HASH. It is possible when ARRAY has even count of elements
and applicator has methods with names of each element with even index (0, 2, 4...).

    app => {
        sessions => [
            default_expiration => 1800,
            cookie_name => 'cookieName'
        ]
    }

    # Will do (note about order):
    $app->sessions->default_expiration(1800);
    $app->sessions->cookie_name('cookieName');


If ARRAY couldn't be treated like ordered HASH, then for each value
will be performed applicator configuring on current key:

    app => {
        routes => {
            get => [
                \"...some data 1...",
                \"...some data 2...",
                \"...some data 3...",
            ]
        }
    }

    # It is like a multiple configuring on the same key ('get' in current example)
    app => { routes => { get => \"...some data 1..." } }
    app => { routes => { get => \"...some data 2..." } }
    app => { routes => { get => \"...some data 3..." } }

    # So, it will do
    $app->routes->get( eval("...some data 1...") );
    $app->routes->get( eval("...some data 2...") );
    $app->routes->get( eval("...some data 3...") );

=attr SCALAR

Will perform applicator configuring on current key
with expression C<eval> of value

    app => {
        routes => {
            get => \"...some data 1..."
        }
    }

    # Will do
    $app->routes->get( eval("...some data 1...") );

In C<eval> will be accessible some variables:

=over 2

=item C<$self> - current plugin instance

=item C<$app> - current application instance

=item C<$applicator> - current applicator instance

In example applicator is C<routes>.

=item C<$config> - current scalar ref to evaluate

=item C<$key> - current config key for applicator

=back

B<Note:> this behaviour is disabled by default due to possible security risks.
You can enable it by passing C<pretty_cfg_scalar> option to C<true>:

    # Mojolicious::Lite
    plugin PrettyConfig => { pretty_cfg_scalar => 1 };


=attr CODE

Will perform applicator configuring on current key with returned value of code
execution.

Code will be called with C<$app> argument.

    app => {
        routes => {
            get => sub { '/boo' => { controller => 'controller', action => 'do_boo' } => 'boo_action' }
        }
    }

    # Will do
    $app->routes->get(
        ( sub {
            '/boo'
            =>  {
                    controller => 'controller',
                    action     => 'do_boo'
                }
            => 'boo_action'
        } )->($app)
    );

B<Note:> this behaviour is disabled by default due to possible security risks.
You can enable it by passing C<pretty_cfg_code> option to C<true>:

    # Mojolicious::Lite
    plugin PrettyConfig => { pretty_cfg_code => 1 };


=attr REF

Will perform applicator configuring on current key with dereferenced value

    app => {
        secrets  => \[ 'mySecret', 'myOldSecret' ],
    }

    # Will do
    $app->secrets( [ 'mySecret', 'myOldSecret' ] );


=attr All others

Will perform applicator configuring on current key with value

    app => {
        moniker => 'MyApp'
    }

    # Will do
    $app->moniker('MyApp');
