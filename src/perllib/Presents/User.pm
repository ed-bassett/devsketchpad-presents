package Presents::User;

use strict;
use warnings;

use base qw(Exporter);

use Presents::Conf qw(
	config
);

our @EXPORT_OK = qw(
	get_people
	get_person
	change_password
);

use Digest::SHA1;

use Presents::DB qw(db_connect);

sub check_password
{
	my ($arg) = @_;	

	my $person = get_person({
		'id' => $arg->{'id'},
	});

	if( $person and $person->{'password'} eq Digest::SHA1::sha1_hex( $arg->{'password'}, config(q{secret}) ))
	{
		return 1;
	}
}

sub change_password
{
	my ($arg) = @_;	

	my $id = $arg->{'id'};

	my $is_password_correct = check_password({
		'id'       => $id,
		'password' => $arg->{'password'},
	});

	if ( $is_password_correct )
	{
		set_password({
			'id'       => $id,
			'password' => $arg->{'new_password'},
		});
	}
	else
	{
		die q{wrong password};
	}
}

sub set_password
{
	my ($arg) = @_;	

	my $dbh = db_connect();

	my $sth = $dbh->prepare(q{
		UPDATE
			person
		SET
			password=?
		WHERE
			id=?
	}) or die $dbh->errstr;

	$sth->execute(
		Digest::SHA1::sha1_hex( $arg->{'password'}, config(q{secret}) ),
		$arg->{'id'}
	) or die $sth->errstr;

	return;
}

sub get_person
{
	my ($arg) = @_;

	my $dbh = db_connect();

	my $username = $arg->{'username'};
	my $id       = $arg->{'id'};

	if( not defined $username xor defined $id )
	{
		return;
	}

	my $sth = $dbh->prepare(q{
		SELECT
			id,
			username,
			password,
			name,
			lastname,
			birthday
		FROM
			person
		WHERE} . (
			defined $username ? q{
			username=?}
			: q{
			id=?}
	)) or die $dbh->errstr;

	$sth->execute(defined $username?$username:$id);

        my @data = $sth->fetchrow_array();

	if ( @data )
	{
	        my %person = ();
        	@person{qw{id username password firstname lastname birthday}} = @data;
	        return \%person;
	}
	return;
}

sub get_people
{
	my ($arg) = @_;	

	my $dbh = db_connect();

	my @ids = @{$arg->{'ids'}||[]};

	my $sth = $dbh->prepare(q{
		SELECT
			id,
			name
		FROM
			person
        WHERE
            archived_at IS NULL
	} . ( scalar @ids
			? ( q{AND person.id IN (} . join(q{, }, (q{?}) x scalar @ids) . q{)})
			: q{}
		)
	) or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute(@ids) or die "Couldn't execute statement: " . $sth->errstr;

	my @people = ();

	while (my @data = $sth->fetchrow_array()) {
		my %person = ();
		@person{qw{id name}} = @data;
		push @people, \%person;
	}

	return \@people;
}

1;
