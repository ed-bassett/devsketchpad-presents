package Presents::DB;

use strict;
use warnings;

use base qw(Exporter);

our @EXPORT_OK = qw(
	db_connect
);

use DBI;

use Conf qw(config);

sub db_connect
{
	my %config = %{config(q{db})};

	return DBI->connect_cached(
		q{dbi:mysql:} .
		$config{'name'},
		$config{'user'},
		$config{'pass'},
	);
}

1;
