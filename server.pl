#!/usr/bin/perl -w

use strict;

use Dancer;
use Google::ProtocolBuffers;
use JSON qw( -convert_blessed_universally );
use ZeroMQ qw( :all );
use Data::Dumper;

my %addresses = @ARGV;

set logger => 'console';

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

my %mapping = (
  Foo => 'FooCommand',
);

my $ctx = ZeroMQ::Context->new();

foreach my $address (keys %addresses) {
  my $socket = $ctx->socket(ZMQ_REQ);
  $socket->connect($addresses{$address});
  $addresses{$address} = $socket;
}

get '/proto2rest/:type/:id' => sub {
  my $type = params->{type};

  send_error("Unknown type") unless $addresses{$type};
  my $socket = $addresses{$type};

  my $command = FooCommand->encode({
    command => Command::GET(),
    id      => params->{id},
  });

  $socket->send($command);
  my $obj = $socket->recv()->data;

  if ($obj) {
    my $json = JSON->new->allow_blessed->convert_blessed->encode($type->decode($obj));

    return $json;
  } else {
    send_error("No $type for " . params->{id});
  }
};

post '/proto2rest/:type/:id' => sub {
  my $type = params->{type};

  send_error("Unknown type") unless $addresses{$type};
  my $socket = $addresses{$type};

  my $body = decode_json(params->{body});

  my $type_cmd = $mapping{$type};

  my $command = $type_cmd->encode({
    command => Command::POST(),
    id      => params->{id},
    foo     => $body,
  });

  $socket->send($command);
  $socket->recv();

  return;
};

dance;
