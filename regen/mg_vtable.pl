#!/usr/bin/perl -w
#
# Regenerate (overwriting only if changed):
#
#    mg_vtable.h
#
# from information stored in this file.
#
# Accepts the standard regen_lib -q and -v args.
#
# This script is normally invoked from regen.pl.

use strict;
require 5.004;

BEGIN {
    # Get function prototypes
    require 'regen/regen_lib.pl';
}

# These have a subtly different "namespace" from the magic types.
my @sig =
    (
     'sv' => {get => 'get', set => 'set', len => 'len'},
     'env' => {set => 'set_all_env', clear => 'clear_all_env'},
     'envelem' => {set => 'setenv', clear => 'clearenv'},
     'sigelem' => {get => 'getsig', set => 'setsig', clear => 'clearsig',
		   cond => '#ifndef PERL_MICRO'},
     'pack' => {len => 'sizepack', clear => 'wipepack'},
     'packelem' => {get => 'getpack', set => 'setpack', clear => 'clearpack'},
     'dbline' => {set => 'setdbline'},
     'isa' => {set => 'setisa', clear => 'clearisa'},
     'isaelem' => {set => 'setisa'},
     'arylen' => {get => 'getarylen', set => 'setarylen', const => 1},
     'arylen_p' => {free => 'freearylen_p'},
     'mglob' => {set => 'setmglob'},
     'nkeys' => {get => 'getnkeys', set => 'setnkeys'},
     'taint' => {get => 'gettaint', set => 'settaint'},
     'substr' => {get => 'getsubstr', set => 'setsubstr'},
     'vec' => {get => 'getvec', set => 'setvec'},
     'pos' => {get => 'getpos', set => 'setpos'},
     'uvar' => {get => 'getuvar', set => 'setuvar'},
     'defelem' => {get => 'getdefelem', set => 'setdefelem'},
     'regexp' => {set => 'setregexp', alias => [qw(bm fm)]},
     'regdata' => {len => 'regdata_cnt'},
     'regdatum' => {get => 'regdatum_get', set => 'regdatum_set'},
     'amagic' => {set => 'setamagic', free => 'setamagic'},
     'amagicelem' => {set => 'setamagic', free => 'setamagic'},
     'backref' => {free => 'killbackrefs'},
     'ovrld' => {free => 'freeovrld'},
     'utf8' => {set => 'setutf8'},
     'collxfrm' => {set => 'setcollxfrm',
		    cond => '#ifdef USE_LOCALE_COLLATE'},
     'hintselem' => {set => 'sethint', clear => 'clearhint'},
     'hints' => {clear => 'clearhints'},
);

my $h = open_new('mg_vtable.h', '>',
		 { by => 'regen/mg_vtable.pl', file => 'mg_vtable.h',
		   style => '*' });

{
    my @names = map {"want_vtbl_$_"} grep {!ref $_} @sig;
    push @names, 'magic_vtable_max';
    local $" = ",\n    ";
    print $h <<"EOH";
enum {		/* pass one of these to get_vtbl */
    @names
};

EOH
}

print $h <<'EOH';
/* These all need to be 0, not NULL, as NULL can be (void*)0, which is a
 * pointer to data, whereas we're assigning pointers to functions, which are
 * not the same beast. ANSI doesn't allow the assignment from one to the other.
 * (although most, but not all, compilers are prepared to do it)
 */

/* order is:
    get
    set
    len
    clear
    free
    copy
    dup
    local
*/

#ifdef DOINIT
EXT_MGVTBL PL_magic_vtables[magic_vtable_max] = {
EOH

my @vtable_names;
my @aliases;

while (my ($name, $data) = splice @sig, 0, 2) {
    push @vtable_names, $name;
    my @funcs = map {
	$data->{$_} ? "Perl_magic_$data->{$_}" : 0;
    } qw(get set len clear free copy dup local);

    $funcs[0] = "(int (*)(pTHX_ SV *, MAGIC *))" . $funcs[0] if $data->{const};
    my $funcs = join ", ", @funcs;

    # Because we can't have a , after the last {...}
    my $comma = @sig ? ',' : '';

    print $h "$data->{cond}\n" if $data->{cond};
    print $h "  { $funcs }$comma\n";
    print $h <<"EOH" if $data->{cond};
#else
  { 0, 0, 0, 0, 0, 0, 0, 0 }$comma
#endif
EOH
    foreach(@{$data->{alias}}) {
	push @aliases, "#define want_vtbl_$_ want_vtbl_$name\n";
	push @vtable_names, $_;
    }
}

print $h <<'EOH';
};
#else
EXT_MGVTBL PL_magic_vtables[magic_vtable_max];
#endif

EOH

print $h (sort @aliases), "\n";

print $h "#define PL_vtbl_$_ PL_magic_vtables[want_vtbl_$_]\n"
    foreach sort @vtable_names;

read_only_bottom_close_and_rename($h);