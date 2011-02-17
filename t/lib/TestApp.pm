package TestApp;

use Catalyst::Runtime 5.80;
use Moose;

extends 'Catalyst';

# Go!
__PACKAGE__->setup(qw(
	Reverse
));


1;

