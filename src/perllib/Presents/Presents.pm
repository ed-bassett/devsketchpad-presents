package Presents::Presents;

use strict;
use warnings;

use base qw(Exporter);

our @EXPORT_OK = qw(
	get_item
	get_items
	get_items_for
	get_gifts_from
	get_pending_items_for
	get_categories
	add_item
	update_item
	get_preference
	set_preference
	update_preference
	choose_gift
	remove_gift_choice
);

use Presents::DB qw(db_connect);

sub get_item
{
	my ($arg) = @_;

	my $dbh = db_connect();

	my $sth = $dbh->prepare(q{
		SELECT
			id,
			name,
			category_id
		FROM
			item
		WHERE
			id like ?
	}) or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute( $arg->{'id'} ) or die "Couldn't execute statement: " . $sth->errstr;

	my @items = ();

	while (my @data = $sth->fetchrow_array()) {
		my %item = ();
		@item{qw{id name category_id description}} = @data;
		push @items, \%item;
	}

	return \@items;
}

sub get_items
{
	my ($arg) = @_;

	my $dbh = db_connect();

	my $sth = $dbh->prepare(q{
		SELECT id, name
		FROM
			item as i
		WHERE
			i.name like ?
	}) or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute(q{%} . $arg->{'name'} . q{%}) or die "Couldn't execute statement: " . $sth->errstr;

	my @items = ();

	while (my @data = $sth->fetchrow_array()) {
		my %item = ();
		@item{qw{id name}} = @data;
		push @items, \%item;
	}

	return \@items;
}

sub get_items_for
{
	my ($arg) = @_;

	my $dbh = db_connect();

	my $sth = $dbh->prepare(q{
		SELECT
			i.id,
			i.name,
			p.id,
			p.preference,
			p.quantity,
			p.price,
			p.comment,
			c.name,
			g.id,
			g.from_person_id
		FROM
			item as i
		LEFT JOIN
			preference as p
		ON
			(i.id = p.item_id)
		LEFT JOIN
			category as c
		ON
			(i.category_id = c.id)
		LEFT OUTER JOIN
			gift as g
		ON
			(i.id = g.item_id AND p.person_id=g.to_person_id)
		WHERE
			p.person_id = ?
	}) or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute($arg->{'id'}) or die "Couldn't execute statement: " . $sth->errstr;

	my @items = ();

	while (my @data = $sth->fetchrow_array()) {
		my %item = ();
		@item{qw{id name preference_id preference quantity price comment category gift_id from_person_id}} = @data;
		push @items, \%item;
	}

	my %items = ();
	my %gifts = ();

	foreach my $item (@items)
	{
		push @{$gifts{$item->{'id'}}}, (
			defined $item->{'gift_id'}
				? {
					'gift_id'        => delete $item->{'gift_id'},
					'from_person_id' => delete $item->{'from_person_id'},
				} : ()
		);

		$items{$item->{'id'}} = $item;
	}
	
	my @unique_items = values %items;

	foreach my $item (@unique_items)
	{
		$item->{'gifts'} = $gifts{$item->{'id'}};
	}

	return \@unique_items;
}

sub get_gifts_from
{
	my ($arg) = @_;

	my $dbh = db_connect();

	my $sth = $dbh->prepare(q{
		SELECT
			i.id,
			i.name,
			g.to_person_id,
			g.id,
			p.comment,
			p.price,
			p.preference
		FROM
			item AS i
		LEFT JOIN
			gift AS g
		ON
			(i.id = g.item_id)
		LEFT JOIN
			preference as p
		ON
			(
				i.id = p.item_id
			AND
				g.to_person_id = p.person_id
			)
		WHERE
			g.from_person_id = ?
	}) or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute($arg->{'id'}) or die "Couldn't execute statement: " . $sth->errstr;

	my @items = ();

	while (my @data = $sth->fetchrow_array()) {
		my %item = ();
		@item{qw{id name to_person_id gift_id comment price preference}} = @data;
		push @items, \%item;
	}

	$sth = $dbh->prepare(q{
		SELECT
			u.name
		FROM
			person as u
		WHERE
			u.id IN (
				SELECT
					from_person_id
				FROM
					gift AS g
				WHERE
					g.item_id=?
			)		
	});

	foreach my $item ( @items )
	{
		$sth->execute($item->{'id'}) or die "Couldn't execute statement: " . $sth->errstr;

		my @names = ();

		while (my @data = $sth->fetchrow_array()) {
			push @names, $data[0];
		}
		$item->{'from_names'} = \@names;
	}

	return \@items;	
}

sub get_pending_items_for
{
	my ($arg) = @_;

	my $dbh = db_connect();

	my $sth = $dbh->prepare(q{
		SELECT
			i.id,
			i.name,
			c.name
		FROM
			item as i
		LEFT JOIN
			category as c
		ON
			(i.category_id = c.id)
		WHERE
			i.id NOT IN (
				SELECT
					item_id
				FROM
					preference
				WHERE
					person_id=?
			)
	}) or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute($arg->{'id'}) or die "Couldn't execute statement: " . $sth->errstr;

	my @items = ();

	while (my @data = $sth->fetchrow_array()) {
		my %item = ();
		@item{qw{id name category}} = @data;
		push @items, \%item;
	}

	return \@items;
}

sub get_categories
{
	my $dbh = db_connect();

	my $sth = $dbh->prepare(q{
		SELECT
			id,
			name
		FROM
			category
	}) or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;

	my @categories = ();

	while (my @data = $sth->fetchrow_array()) {
		my %category = ();
		@category{qw{id name}} = @data;
		push @categories, \%category;
	}

	return \@categories;
}

sub add_item
{
	my ($arg) = @_;

	my $dbh = db_connect();

	my $sth = $dbh->prepare(q{
		INSERT INTO item (
			name,
			category_id
		)
		VALUES
		(
			?,?
		)
	}) or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute(
		$arg->{name},
		$arg->{category_id},
	) or die "Couldn't execute statement: " . $sth->errstr;

	return $dbh->last_insert_id(undef, undef, undef, undef);
}

sub update_item
{
	my ($arg) = @_;

	my $dbh = db_connect();

	# field name => value only of values to be updated
	my %fields = map { (exists $arg->{$_}) ? ( $_ => $arg->{$_} ) : () } qw(name category_id);

	my $sth = $dbh->prepare(q{
		UPDATE item
		SET } . join( q{,}, map {$_ . q{=?}} sort keys %fields ) . q{
		WHERE
			id=?
		
	}) or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute(
		(map {$fields{$_}} sort keys %fields),
		$arg->{'id'}
	) or die "Couldn't execute statement: " . $sth->errstr;
	
	return;
}

sub get_preference
{
	my ($arg) = @_;

	my $dbh = db_connect();

	my $sth = $dbh->prepare(q{
		SELECT
			person_id,
			item_id,
			preference,
			price,
			quantity,
			comment
		FROM
			preference
		WHERE
			id=?
	}) or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute($arg->{'id'}) or die "Couldn't execute statement: " . $sth->errstr;

	my @data = $sth->fetchrow_array();
	my %preference = ();
	@preference{qw{person_id item_id preference price quantity comment}} = @data;

	return \%preference;
}

sub set_preference
{
	my ($arg) = @_;

	my $dbh = db_connect();

	my $sth = $dbh->prepare(q{
		INSERT INTO preference (
			person_id,
			item_id,
			preference,
			quantity,
			price,
			comment
		)
		VALUES
		(
			?,?,?,?,?,?
		)		
	}) or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute(
		$arg->{person},
		$arg->{item},
		$arg->{preference},
		$arg->{quantity},
		$arg->{price},
		$arg->{comment},
	) or die "Couldn't execute statement: " . $sth->errstr;

	return;
}

sub update_preference
{
	my ($arg) = @_;

	my $dbh = db_connect();

	# field name => value only of values to be updated
	my %fields = map { (exists $arg->{$_}) ? ( $_ => $arg->{$_} ) : () } qw(preference quantity price comment);

	my $sth = $dbh->prepare(q{
		UPDATE preference
		SET } . join( q{,}, map {$_ . q{=?}} sort keys %fields ) . q{
		WHERE
			id=?
		
	}) or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute(
		(map {$fields{$_}} sort keys %fields),
		$arg->{preference_id},
	) or die "Couldn't execute statement: " . $sth->errstr;

	return;
}

sub choose_gift
{
	my ($arg) = @_;

	my $dbh = db_connect();

	my $sth = $dbh->prepare(q{
		INSERT INTO gift (
			from_person_id,
			to_person_id,
			item_id
		)
		VALUES
		(
			?,?,?
		)		
	}) or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute(
		$arg->{from_id},
		$arg->{to_id},
		$arg->{item_id},
	) or die "Couldn't execute statement: " . $sth->errstr;

	return;	
}

sub remove_gift_choice
{
	my ($arg) = @_;

	my $dbh = db_connect();

	my $sth = $dbh->prepare(q{
		DELETE FROM 
			gift
		WHERE
			id=?
		
	}) or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute(
		$arg->{gift_id},
	) or die "Couldn't execute statement: " . $sth->errstr;

	return;
}


1;
