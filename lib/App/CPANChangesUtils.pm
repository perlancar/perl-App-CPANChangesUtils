package App::CPANChangesUtils;

use 5.010001;
use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

our %SPEC;

our %argspecs_common = (
    file => {
        schema => 'filename*',
        summary => 'If not specified, will look for file called '.
        'Changes/ChangeLog in current directory',
        pos => 0,
    },
    class => {
        schema => 'perl::modname*',
        default => 'CPAN::Changes',
    },
);

$SPEC{parse_cpan_changes} = {
    v => 1.1,
    summary => 'Parse CPAN Changes file',
    description => <<'_',

This utility is a simple wrapper for <pm:CPAN::Changes>.

_
    args => {
        %argspecs_common,
        unbless => {
            summary => 'Whether to return Perl objects as unblessed refs',
            schema => 'bool*',
            default => 1,
            description => <<'_',

If you set this to false, you'll need to use an output format that can handle
serializing Perl objects, e.g. on the CLI using `--format=perl`.

_
        },
    },
};
sub parse_cpan_changes {
    require Data::Structure::Util;

    my %args = @_;
    my $unbless = $args{unbless} // 1;
    my $class = $args{class} // 'CPAN::Changes';
    (my $class_pm = "$class.pm") =~ s!::!/!g;
    require $class_pm;

    my $file = $args{file};
    if (!$file) {
	for (qw/Changes ChangeLog/) {
	    do { $file = $_; last } if -f $_;
	}
    }
    return [400, "Please specify file ".
                "(or run in directory where Changes file exists)"]
        unless $file;

    my $ch = $class->load($file);
    [200, "OK", $unbless ? Data::Structure::Util::unbless($ch) : $ch];
}

$SPEC{format_cpan_changes} = {
    v => 1.1,
    summary => 'Format CPAN Changes',
    description => <<'_',

This utility is a simple wrapper to <pm:CPAN::Changes>. It will parse your CPAN
Changes file into data structure, then use `serialize()` to format it back to
text form.

_
    args => {
        %argspecs_common,
    },
};
sub format_cpan_changes {
    my %args = @_;

    my $res = parse_cpan_changes(%args, unbless=>0);
    return $res unless $res->[0] == 200;
    [200, "OK", $res->[2]->serialize];
}

1;
# ABSTRACT:

=head1 DESCRIPTION

This distribution provides some CLI utilities related to CPAN Changes


=head1 SEE ALSO

L<CPAN::Changes>

L<CPAN::Changes::Spec>

An alternative way to manage your Changes using INI master format:
L<Module::Metadata::Changes>.

Dist::Zilla plugin to check your Changes before build:
L<Dist::Zilla::Plugin::CheckChangesHasContent>,
L<Dist::Zilla::Plugin::CheckChangeLog>.

=cut
