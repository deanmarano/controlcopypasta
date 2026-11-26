#!/usr/bin/perl
# Press a key chord on the remote Firefox's X display by speaking RFB to the
# container's internal, unauthenticated VNC socket. Used to fire extension
# hotkeys (Save Page WE = Alt+A) that no WebExtension API can trigger.
#
#   docker exec -i remote-firefox.web.1 perl - alt a < vnc-key.pl
#
# Connects as a *shared* client so an open noVNC viewer is not kicked off.
use strict;
use warnings;
use IO::Socket::UNIX;

my %SYM = (alt => 0xffe9, ctrl => 0xffe3, shift => 0xffe1, enter => 0xff0d, esc => 0xff1b);
my @keys = map { exists $SYM{lc $_} ? $SYM{lc $_} : ord($_) } @ARGV;
die "usage: vnc-key.pl <key> [key...]\n" unless @keys;

my $path = $ENV{VNC_SOCK} || '/tmp/vnc.sock';
my $s = IO::Socket::UNIX->new(Peer => $path) or die "connect $path: $!\n";
binmode $s;

sub rd {
  my ($n) = @_;
  my $buf = '';
  while (length($buf) < $n) {
    my $r = sysread($s, $buf, $n - length($buf), length($buf));
    die "vnc: short read\n" unless $r;
  }
  return $buf;
}

rd(12);                                   # "RFB 003.008\n"
syswrite($s, "RFB 003.008\n");
my $n = unpack('C', rd(1));
die "vnc: server refused\n" unless $n;
my %types = map { $_ => 1 } unpack('C*', rd($n));
die "vnc: socket wants a password (no None auth)\n" unless $types{1};
syswrite($s, pack('C', 1));               # security type None
die "vnc: auth failed\n" if unpack('N', rd(4));
syswrite($s, pack('C', 1));               # ClientInit, shared = 1
my $init = rd(24);
rd(unpack('N', substr($init, 20, 4)));    # desktop name

sub key { syswrite($s, pack('CCnN', 4, $_[1], 0, $_[0])); select(undef, undef, undef, 0.06); }
key($_, 1) for @keys;
key($_, 0) for reverse @keys;
select(undef, undef, undef, 0.2);
close $s;
print "ok\n";
