package TestApp::Controller::Foo::Bar;

use Moose;

BEGIN { extends 'Catalyst::Controller' }


sub test :Local :Args(0) {
	# simple 'ok'
	$_[1]->res->body('ok');
}


__PACKAGE__->meta->make_immutable;

1;


