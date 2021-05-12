#!/usr/bin/env perl

use strict;
use DBIx::Connector;

my $user_db = '';
my $pass_db = '';
my $host_db = '';
my $name_db = '';

my $data_source = "dbi:mysql:database=$name_db;mysql_client_found_rows=1;mysql_enable_utf8=1;host=$host_db";

my $DBH = DBIx::Connector->new($data_source, $user_db, $pass_db, {
	RaiseError => 1,
	AutoCommit => 1,
	mysql_enable_utf8 => 1,
});

$DBH->mode('ping');

while (<>) {
	
	chomp($_);
	my @data = split /\s/, $_;
	my ($ts,$int_id);

	#timestamp
	$ts = "$data[0] $data[1]";

	#internal id
	$int_id = $data[2];

	#log without ts
	#@data[2..$#data]
	my $msg = substr($_,20);

	if ( $data[3] eq '<=' ) {
		
		my $id;
		$_ =~ /id=(.*)\s{0,}/i;

		#id
		if ( $1 ) {
			$id = $1;
		}
		else {
			$id = 0;
		}

		my $SQL = 'INSERT INTO `message` (`created`, `id`, `int_id`, `str`) VALUES ((?),(?),(?),(?))';
		my $query = $DBH->run(sub {
			my $query = $_->prepare($SQL);
			$query->execute($ts,$id,$int_id,$msg);
			$query;
		});

		#print "MESSAGE: $ts;$id;$int_id;$msg\n";

	}
	else {

		#email rec.
		my $email;
		if ( $data[4] =~ /^[\w-\.]+@([\w-]+\.)+[\w-]{2,8}$/g ) {
			$email = $data[4];
		}

		my $SQL = 'INSERT INTO `log` (`created`, `int_id`, `str`, `address`) VALUES ((?),(?),(?),(?))';
		my $query = $DBH->run(sub {
			my $query = $_->prepare($SQL);
			$query->execute($ts,$int_id,$msg,$email);
			$query;
		});

		#print "LOG: $ts;$int_id;$msg;$email\n";

	}

}

