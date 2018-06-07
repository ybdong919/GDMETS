#!/usr/bin/perl 

##### Two commandline arguments are required.
use strict;
use DBI;

my $database = 'orthomcl';
my $hostname = 'mysql_local_infile=1:127.0.0.1:3307';
my $username = $ARGV[0];  #'schema'
my $password = $ARGV[1];  #'1234'

my $drh =DBI ->install_driver('mysql'); 
my $rc = $drh->func("createdb", $database,$hostname, $username, $password, 'admin');#create a new ampty 'orthomcl' database
