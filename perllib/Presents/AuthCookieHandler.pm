package Presents::AuthCookieHandler;

use strict;
use warnings;

use base qw(Apache2::AuthCookie);

use Digest::SHA1;

use Presents::Conf qw(
	config
);
 
use Presents::User qw(
	get_person
);

sub authen_cred {
	my $self = shift;
	my $r = shift;
	my ($username, $password) = @_;

	if ( _is_valid_user($username, $password,$r) ) {
		my $session_key
			= $username
			. '::'
			. Digest::SHA1::sha1_hex( $username, config(q{secret}) )
			;

		return $session_key;
	}
}

sub authen_ses_key {
	my $self = shift;
	my $r = shift;
	my $session_key = shift;

	my ($username, $mac) = split /::/, $session_key;

	if ( Digest::SHA1::sha1_hex( $username, config(q{secret}) ) eq $mac ) {
		return $username;
	}
}

sub _is_valid_user
{
	my ( $username, $password, $r ) = @_;

	my $person = get_person({
		'username' => $username
	});

	if( $person and $person->{'password'} eq Digest::SHA1::sha1_hex( $password, config(q{secret}) ))
	{
		return 1;
	}

	return;
}

1;

__END__
