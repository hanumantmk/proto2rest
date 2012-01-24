#!/usr/bin/perl -w

use strict;

use Google::ProtocolBuffers;
use ZeroMQ qw( :all );

my $addr = $ARGV[0] or die "Please enter an address to bind to";

Google::ProtocolBuffers->parse(<<PROTO
  message Foo {
    required string a = 1;
    required string b = 2;
    required string c = 3;
  }
  enum Command {
    GET  = 1;
    POST = 2;
  };

  message FooCommand {
    required Command command = 1;
    required string id       = 2;
    optional Foo foo         = 3;
  }
PROTO
);

my %objects;

my $ctx = ZeroMQ::Context->new();

my $socket = $ctx->socket(ZMQ_REP);
$socket->bind($addr);
use Data::Dumper;

while (1) {
  my $cmd = FooCommand->decode($socket->recv()->data);

  if ($cmd->{command} == Command::GET()) {
    $socket->send($objects{$cmd->{id}} ? $objects{$cmd->{id}}->encode() : "");
  } elsif ($cmd->{command} == Command::POST()) {
    $objects{$cmd->{id}} = $cmd->{foo};
    $socket->send("");
  }
}
