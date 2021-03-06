#!perl
#
# This file is part of HTTP-Tiny
#
# This software is copyright (c) 2011 by Christian Hansen.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Test::More qw[no_plan];
use t::Util    qw[tmpfile rewind $CRLF $LF];
use HTTP::Tiny;

{
    no warnings 'redefine';
    sub HTTP::Tiny::Handle::can_read  { 1 };
    sub HTTP::Tiny::Handle::can_write { 1 };
}

{
    my $header = join $CRLF, 'Foo: Foo', 'Foo: Baz', 'Bar: Bar', '', '';
    my $fh     = tmpfile($header);
    my $exp    = { foo => ['Foo', 'Baz'], bar => 'Bar' };
    my $handle = HTTP::Tiny::Handle->new(fh => $fh);
    my $got    = $handle->read_header_lines;
    is_deeply($got, $exp, "->read_header_lines() CRLF");
}

{
    my $header = join $LF, 'Foo: Foo', 'Foo: Baz', 'Bar: Bar', '', '';
    my $fh     = tmpfile($header);
    my $exp    = { foo => ['Foo', 'Baz'], bar => 'Bar' };
    my $handle = HTTP::Tiny::Handle->new(fh => $fh);
    my $got    = $handle->read_header_lines;
    is_deeply($got, $exp, "->read_header_lines() LF");
}

{
    my $header = "Foo: $CRLF\x09Bar$CRLF\x09$CRLF\x09Baz$CRLF$CRLF";
    my $fh     = tmpfile($header);
    my $exp    = { foo => 'Bar Baz' };
    my $handle = HTTP::Tiny::Handle->new(fh => $fh);
    my $got    = $handle->read_header_lines;
    is_deeply($got, $exp, "->read_header_lines() insane continuations");
}

{
    my $fh      = tmpfile();
    my $handle  = HTTP::Tiny::Handle->new(fh => $fh);
    my $headers = { foo => ['Foo', 'Baz'], bar => 'Bar' };
    $handle->write_header_lines($headers);
    rewind($fh);
    is_deeply($handle->read_header_lines, $headers, "roundtrip header lines");
}

