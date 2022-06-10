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

our $re_rel_metadata = qr/(?:([A-Za-z]+(?:-[A-Za-z]+)*):\s*([^;]*))/;

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
        parse_release_metadata => {
            summary => 'Whether to parse release metadata in release note',
            schema => 'bool*',
            default => 1,
            description => <<'_',

If set to true (the default), the utility will attempt to parse release metadata
in the release note. The release note is the text after the version and date in
the first line of a release entry:

    0.001 - 2022-06-10 THIS IS THE RELEASE NOTE AND CAN BE ANY TEXT

One convention I use is for the release note to be semicolon-separated of
metadata entries, where each metadata is in the form of HTTP-header-like "Name:
Value" text where Name is dash-separated words and Value is any text that does
not contain newline or semicolon. Example:

    0.001 - 2022-06-10  Urgency: high; Backward-Incompatible: yes

Note that Debian changelog also supports "key=value" in the release line.

This option, when enabled, will first check if the release note is indeed in the
form of semicolon-separated metadata. If yes, will create a key called
C<metadata> in the release result structure containing a hash of metadata:

    { "urgency" => "high", "backward-incompatible" => "yes" }

Note that the metadata names are converted to lowercase.

_
        },
    },
};
sub parse_cpan_changes {
    require Data::Structure::Util;

    my %args = @_;
    my $unbless = $args{unbless} // 1;
    my $parse_release_metadata = $args{parse_release_metadata} // 1;
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

    if ($parse_release_metadata) {
        for my $rel ($ch->releases) {
            my $note = $rel->note;
            if ($note =~ /\A$re_rel_metadata(?:;\s*$re_rel_metadata)*/) {
                my $meta = {};
                while ($note =~ /$re_rel_metadata/g) {
                    $meta->{lc $1} = $2;
                }
                $rel->{metadata} = $meta;
            }
        }
    }

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
