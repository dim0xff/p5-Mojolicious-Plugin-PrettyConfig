use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

plugin 'DefaultHelpers';
plugin 'PrettyConfig' => {
    default => {
        app => [
            secrets  => \[ 'mySecret', 'myOldSecret' ],
            sessions => {
                default_expiration => 1234,
                cookie_name        => 'testAppSession',
            },
            routes => {
                get => [
                    \" '/foo' => { controller => 'Controller::Foo', action => 'do_foo' } => 'foo_action' ",
                    sub {
                        '/boo' => {
                            controller => 'Controller::Boo',
                            action     => 'do_boo'
                        } => 'boo_action';
                    },
                ]
            },
            static => [
                extra => \{},
                paths => \[],
            ],
        ]
    },
    pretty_cfg_code   => 1,
    pretty_cfg_scalar => 1,
};

# Test

my $t = Test::Mojo->new;
$t->get_ok('/foo')->status_is(200)->content_like(qr/Foo! foo_action/);
$t->get_ok('/boo')->status_is(200)->content_like(qr/Boo! boo_action/);

is_deeply( app->secrets, [ 'mySecret', 'myOldSecret' ], 'secrets' );
is( app->sessions->cookie_name, 'testAppSession', 'sessions->cookie_name' );
is( app->sessions->default_expiration, 1234, 'sessions->default_expiration' );

is_deeply( app->static->extra, {}, 'static->extra');
is_deeply( app->static->paths, [], 'static->paths');

done_testing();


__DATA__

@@ controller/foo/do_foo.html.ep
Foo! <%= $c->match->endpoint->name %>

@@ controller/boo/do_boo.html.ep
Boo! <%= $c->match->endpoint->name %>
