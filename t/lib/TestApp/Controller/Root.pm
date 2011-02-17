package TestApp::Controller::Root;

use Moose;

BEGIN { extends 'Catalyst::Controller' }


__PACKAGE__->config( namespace => '' );


sub t00 :Local :Args(0) {
	# simple 'ok'
	$_[1]->res->body('ok');
}
sub t01 :Local :Args(0) {
	# /t00
	$_[1]->res->body( $_[1]->uri_for_action('/t00') );
}
sub t02 :Local :Args(0) {
	# '' ( stringified)
	$_[1]->res->body( ref $_[1]->uri_for_action('/t01') );
}
sub t03 :Local :Args(0) :ReverseDisable {
	$_[1]->res->body( $_[1]->uri_for_action('/t01') );
}
sub t04 :Local :Args(0) :ReverseNoRelative {
	$_[1]->res->body( $_[1]->uri_for_action('/t01') );
}
sub t05 :Local :Args(0) :ReverseNoRelative :ReverseNoStringify {
	$_[1]->res->body( ref $_[1]->uri_for_action('/t01') );
}
sub t06 :Local :Args(0) :ReverseNoStringify {
	$_[1]->res->body( ref $_[1]->uri_for_action('/t01') );
}
sub t07 :Local :Args(0) {
	$_[1]->res->body( $_[1]->uri_for('/nonexistent') );
}
sub t08 :Local :Args(0) :ReverseNoStrict {
	$_[1]->res->body( $_[1]->uri_for_action('/t01',[1]) );
}
sub t09 :Local :Args(0) {
	eval {
		$_[1]->res->body( $_[1]->uri_for_action('/t01',[1]) );
	};
	$_[1]->res->body('ok') if $@;
}
sub t10 :Local :Args(0) {
	$_[1]->res->body( $_[1]->reverse('t01') );
}
sub t11 :Local :Args(0) {
	$_[1]->res->body( $_[1]->reverse('Root::t01') );
}
sub t12 :Local :Args(0) {
	eval {
		$_[1]->res->body( $_[1]->reverse('Root::nonexistent') );
	};
	$_[1]->res->body( $@ ) if $@;
}
sub t13 :Local :Args(0) {
	$_[1]->res->body( $_[1]->reverse('Foo::Bar::test') );
}
sub t14 :Local :Args(0) {
	eval {
		$_[1]->res->body( $_[1]->reverse('Foo::Bar::nonexistent') );
	};
	$_[1]->res->body( $@ ) if $@;
}
sub t15 :Local :Args(0) {
	eval {
		$_[1]->res->body( $_[1]->reverse('Foo::Bar::') );
	};
	$_[1]->res->body( $@ ) if $@;
}
sub t16 :Local :Args(0) {
	eval {
		$_[1]->res->body( $_[1]->reverse('Foo::None::test') );
	};
	$_[1]->res->body( $@ ) if $@;
}

sub default :Private {
    my ( $self, $c ) = @_;

    $c->res->body( 'not found' );
    $c->res->status(404);
}


__PACKAGE__->meta->make_immutable;

1;

