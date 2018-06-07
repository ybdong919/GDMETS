#!/usr/bin/perl 

##### Two commandline arguments are required.
use strict;
use DBI;

my $hostname = 'mysql_local_infile=1:127.0.0.1:3307';
my $database = 'orthomcl';
my $username = $ARGV[0];  #'schema'
my $password = $ARGV[1];  #'1234'
my $dbh= DBI ->connect("dbi:mysql:${database}:$hostname", $username, $password) or die "Error: $DBI::errstr\n";
my $rc = $dbh->func("dropdb", $database, 'admin'); # drop 'orthomcl' database



