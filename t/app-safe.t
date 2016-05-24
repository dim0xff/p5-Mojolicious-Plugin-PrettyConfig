use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

plugin 'DefaultHelpers';
plugin 'PrettyConfig' => {
    default => {
        app => [
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
        ]
    },
};

# Test

my $t = Test::Mojo->new;
$t->get_ok('/foo')->status_is(404);
$t->get_ok('/boo')->status_is(404);

done_testing();
