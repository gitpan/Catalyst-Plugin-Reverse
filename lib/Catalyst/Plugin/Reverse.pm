package Catalyst::Plugin::Reverse;

=head1 NAME

Catalyst::Plugin::Reverse - Enhanced reverse URI construction

=cut

use Catalyst::Exception;
use Moose::Role;


=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

 # Plugin setup
 use Catalyst qw(
    ...
    Reverse
    ...
 ));

 # Plugin configuration
 __PACKAGE__->config->{'Plugin::Reverse'}{'action'} = 1;
 __PACKAGE__->config->{'Plugin::Reverse'}{'strict'} = 0;

 # Per-action customization
 sub index :Local :ReverseDisable {
     # here 'uri_for' works like generic
 }
 sub view :Local :ReverseStrict {
     # here 'uri_for' raise an exceptions
 }

 # Usage of 'reverse' method
 sub list :Local :Args(0) {
     my ( $self,$c ) = @_;

     my $uri = $c->reverse('Catalog::Item::edit', [1], 2 );
 }


=cut


# lazy accesssor to current plugin settings (depends of call context)
has _reverse => ( is => 'ro', lazy_build => 1 );

sub _build__reverse {
	Catalyst::Plugin::Reverse::ContextualConfig->new( shift )
}


{	# Don't pollute application namespace!
	package Catalyst::Plugin::Reverse::ContextualConfig;

	use Moose;

	# accept single argument only!
	sub BUILDARGS { { app => $_[1] } }

	# catalyst
	has app => ( is => 'ro', weak_ref => 1 );

	# source config
	has config => ( is => 'ro', lazy_build => 1 );

	sub _build_config {
		+{(
			# defaults
			action   => 1,
			base     => '/',
			enabled  => 1,
			relative => 1,
			strict   => 1,
		), %{ shift->app->config->{'Plugin::Reverse'} || {} }}
	}

	# use internally
	has absolute => ( is => 'rw', default => 0 );


=head1 CONFIGURATION

=head2 enabled

Enable plugin functionality entirely. Enabled by default.

=cut

	sub enabled {
		my $self = shift;

		if ( $self->action ) {
			return 1 if exists $self->app->action->attributes->{ ReverseEnable };
			return 0 if exists $self->app->action->attributes->{ ReverseDisable };
		}
		return $self->config->{ enabled };
	}


=head2 strict

Raise Catalyst exception instead returning undefined value during
unsuccessful URI construction. Enabled by default.

=cut

	sub strict {
		my $self = shift;

		if ( $self->action ) {
			return 1 if exists $self->app->action->attributes->{ ReverseStrict };
			return 0 if exists $self->app->action->attributes->{ ReverseNoStrict };
		}
		return $self->config->{ strict };
	};


=head2 relative

Strip C<prefix> from stringified C<uri_for> result.
Enabled dy default.

=cut

	sub relative {
		my $self = shift;

		if ( $self->action ) {
			return 1 if exists $self->app->action->attributes->{ ReverseRelative };
			return 0 if exists $self->app->action->attributes->{ ReverseNoRelative };
		}
		return $self->config->{ relative };
	}


=head2 stringify

Force stringification of URI object from C<uri_for> method.
Implicitly enabled by C<relative> setting.

=cut

	sub stringify {
		my $self = shift;

		# enabled implicitly
		return 1 if $self->relative;

		if ( $self->action ) {
			return 1 if exists $self->app->action->attributes->{ ReverseStringify };
			return 0 if exists $self->app->action->attributes->{ ReverseNoStringify };
		}
		return $self->config->{ stringify };
	}


=head2 prefix

Part to strip from begin of C<uri_for> result while C<relative> enabled.
Default is stringified result of $c->uri_for(C<base>).

=cut

	has 'prefix' => ( is => 'ro', lazy_build => 1 );

	sub _build_prefix {
		my $self = shift;

		# resolve uri for 'base'
		my $prefix = $self->config->{ prefix };

		unless ( $prefix ) {
			local $self->{ relative } = 0;
			$self->absolute(1);
			$prefix = $self->app->uri_for( $self->base ) or
				Catalyst::Exception->throw(
					message => "Can't find uri_for action '" . $self->base . "'" );
			$self->absolute(0);
		}
		return $prefix;
	}


=head2 base

Relative URI to determine C<prefix>. Default is "/".

=cut

	has base => ( is => 'ro', lazy_build => 1 );

	sub _build_base {
		shift->config->{ base };
	}


=head2 action

Enable per-action attributes processing. Enabled by default.

=cut

	has 'action' => ( is => 'ro', lazy_build => 1 );

	sub _build_action {
		shift->config->{ action };
	}


=head1 ACTION ATTRIBUTES

with C<action> setting enabled you can locally override global
plugin settings with special action attributes:

=head2 ReverseDisable / ReverseEnable

Locally override C<enabled> setting.

=head2 ReverseStrict / ReverseNoStrict

Locally override C<strict> setting.

=head2 ReverseStringify / ReverseNoStringify

Locally override C<stringify> setting.

=head2 ReverseRelative / ReverseNoRelative

Locally override C<relative> setting.

=cut

}


=head1 METHODS

=head2 reverse ( $name, \@captures?, @args?, \%query_values? )

URI reverse engineering without guessing.

=head3 $name

Controller (optionally) & method spearated by "::".
If no controller specified current controller assumed as default.
Valid specifications:

=over

=item 'Foo::Bar::view'

Method 'view' in 'App::Controller::Foo::Bar'.

=item 'index'

Method 'index' in current controller.

=back

=head3 \@captures?, @args?, \%query_values?

Passed unchanged to C<uri_for_action> method.

=cut

sub reverse {
	my ($self,$name) = splice @_,0,2;

	my ($cname,$mname) = $name =~ m{^(?:(.+)::)?([^:]+)$} or
		Catalyst::Exception->throw(
			message => qq(Plugin::Reverse: invalid name '$name')
	);

	my $ctrl;
	if ( $cname ) {
		$ctrl = $self->controller( $cname ) or
			Catalyst::Exception->throw(
				message => qq(Plugin::Reverse: can't found controler '$cname')
			);
	} else {
		$ctrl = $self->controller;
		( $cname = ref $ctrl ) =~ s{.*Controller::}{};
	}

	my $actn = $ctrl->action_for( $mname ) or
		Catalyst::Exception->throw(
			message => qq(Plugin::Reverse: can't found method '$mname' in controler '$cname')
	);

	$self->uri_for_action( $actn, @_ );
}


=head2 uri_for

Wrapped C<uri_for> method with optionally strictness, strigificating
and absolute prefix stripping.

=cut

around 'uri_for' => sub {
	my ( $orig,$self ) = splice @_,0,2;

	my $uri = $self->$orig( @_ );

	# plugin disabled completely
	return $uri unless $self->_reverse->enabled;

	# raise!
	Catalyst::Exception->throw(
		message => qq(Can't find uri_for action '$_[0]')
	) if ! defined($uri) && $self->_reverse->strict;

	# 'stringify' disabled
	return $uri unless $self->_reverse->stringify;

	# stringification (take carry about undef)
	$uri = defined $uri ? "$uri" : '';

	# 'relative' disabled permanently or temporary
	return $uri unless
		$self->_reverse->relative && ! $self->_reverse->absolute;

	# relative processing
	my $prefix = $self->_reverse->prefix;
	$uri =~ s{^$prefix}{/};

	return $uri;
};


=head1 AUTHOR

Oleg A. Mamontov, C<< <oleg at mamontov.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-plugin-reverse at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-Reverse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::Reverse


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-Reverse>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-Reverse>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-Reverse>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-Reverse/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Oleg A. Mamontov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;

