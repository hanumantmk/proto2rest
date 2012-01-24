#!/usr/bin/perl -w

use strict;

use LWP::UserAgent;
use JSON;

my $ua = LWP::UserAgent->new();

$ua->post("http://localhost:3000/proto2rest/Foo/1234", { body => encode_json({ a => "foo", b => "bar", c => "baz" })});
