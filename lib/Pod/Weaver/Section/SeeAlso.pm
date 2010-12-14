#
# This file is part of Pod-Weaver-Section-SeeAlso
#
# This software is copyright (c) 2010 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Pod::Weaver::Section::SeeAlso;
BEGIN {
  $Pod::Weaver::Section::SeeAlso::VERSION = '1.001';
}
BEGIN {
  $Pod::Weaver::Section::SeeAlso::AUTHORITY = 'cpan:APOCAL';
}

# ABSTRACT: add a SEE ALSO pod section

use Moose 1.03;
use Moose::Autobox 0.10;

with 'Pod::Weaver::Role::Section' => { -version => '3.100710' };

sub mvp_multivalue_args { qw( links ) }


has add_main_link => (
	is => 'ro',
	isa => 'Bool',
	default => 1,
);


has header => (
	is => 'ro',
	isa => 'Str',
	default => <<'EOPOD',
Please see those modules/websites for more information related to this module.
EOPOD

);


has links => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub { [ ] },
);

sub weave_section {
	## no critic ( ProhibitAccessOfPrivateData )
	my ($self, $document, $input) = @_;

	my $zilla = $input->{zilla} or die 'Please use Dist::Zilla with this module!';

	# find the main module's name
	my $main = $zilla->main_module->name;
	my $is_main = $main eq $input->{filename} ? 1 : 0;
	$main =~ s|^lib/||;
	$main =~ s/\.pm$//;
	$main =~ s|/|::|g;

	# Is the SEE ALSO section already in the POD?
	my $see_also;
	foreach my $i ( 0 .. $#{ $input->{pod_document}->children } ) {
		my $para = $input->{pod_document}->children->[$i];
		next unless $para->isa('Pod::Elemental::Element::Nested')
			and $para->command eq 'head1'
			and $para->content =~ /^SEE\s+ALSO/s;	# catches both "head1 SEE ALSO\n\nL<baz>" and "head1 SEE ALSO\nL<baz>" format

		$see_also = $para;
		splice( @{ $input->{pod_document}->children }, $i, 1 );
		last;
	}

	my @links;
	if ( defined $see_also ) {
		# Transform it into a proper list
		foreach my $child ( @{ $see_also->children } ) {
			if ( $child->isa( 'Pod::Elemental::Element::Pod5::Ordinary' ) ) {
				foreach my $l ( split /\n/, $child->content ) {
					chomp $l;
					next if ! length $l;
					push( @links, $l );
				}
			} else {
				die 'Unknown POD in SEE ALSO: ' . ref( $child );
			}
		}

		# Sometimes the links are in the content!
		if ( $see_also->content =~ /^SEE\s+ALSO\s+(.+)$/s ) {
			foreach my $l ( split /\n/, $1 ) {
				chomp $l;
				next if ! length $l;
				push( @links, $l );
			}
		}
	}
	if ( $self->add_main_link and ! $is_main ) {
		unshift( @links, $main );
	}

	# Add links specified in the document
	# Code copied from Pod::Weaver::Section::Name, thanks RJBS!
	# TODO how do we pick up multiple times?
	my ($extralinks) = $input->{ppi_document}->serialize =~ /^\s*#+\s*SEEALSO:\s*(.+)$/m;
	if ( defined $extralinks and length $extralinks ) {
		# get the list!
		my @data = split( /\,/, $extralinks );
		$_ =~ s/^\s+//g for @data;
		$_ =~ s/\s+$//g for @data;
		push( @links, $_ ) for @data;
	}

	# Add extra links
	push( @links, $_ ) for @{ $self->links };

	if ( @links ) {
		$document->children->push(
			Pod::Elemental::Element::Nested->new( {
				command => 'head1',
				content => 'SEE ALSO',
				children => [
					Pod::Elemental::Element::Pod5::Ordinary->new( {
						content => $self->header,
					} ),
					# I could have used the list transformer but rjbs said it's more sane to generate it myself :)
					Pod::Elemental::Element::Nested->new( {
						command => 'over',
						content => '4',
						children => [
							( map { _make_item( $_ ) } @links ),
							Pod::Elemental::Element::Pod5::Command->new( {
								command => 'back',
								content => '',
							} ),
						],
					} ),
				],
			} ),
		);
	}
}

sub _make_item {
	my( $link ) = @_;

	# Is it proper POD?
	if ( $link !~ /^L\<.+\>$/ ) {
		$link = 'L<' . $link . '>';
	}

	return Pod::Elemental::Element::Nested->new( {
		command => 'item',
		content => '*',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
				content => $link,
			} ),
		],
	} );
}

1;


__END__
=pod

=for Pod::Coverage weave_section mvp_multivalue_args

=for stopwords dist dzil

=head1 NAME

Pod::Weaver::Section::SeeAlso - add a SEE ALSO pod section

=head1 VERSION

  This document describes v1.001 of Pod::Weaver::Section::SeeAlso - released December 13, 2010 as part of Pod-Weaver-Section-SeeAlso.

=head1 DESCRIPTION

This section plugin will produce a hunk of pod that references the main module of a dist
from it's submodules and adds any other text already present in the pod. It will do this
only if it is being built with L<Dist::Zilla> because it needs the data from the dzil object.

In the main module, this section plugin just transforms the links into a proper list. In the
submodules, it also adds the link to the main module.

For an example of what the hunk looks like, look at the L</SEE ALSO> section in this POD :)

WARNING: Please do not put any POD commands in your SEE ALSO section!

What you should do when you want to add extra links is:

	=head1 SEE ALSO
	Foo::Bar
	Bar::Baz
	www.cpan.org

And this module will automatically convert it into:

	=head1 SEE ALSO
	=over 4
	=item *
	L<Main::Module>
	=item *
	L<Foo::Bar>
	=item *
	L<Bar::Baz>
	=item *
	L<www.cpan.org>
	=back

You can specify more links by using the "links" attribute or by specifying it as a comment. The
format of the comment is:

	# SEEALSO: Foo::Bar, Module::Nice::Foo, www.foo.com

At this time you can only use one comment line. If you need to do it multiple times, please prod me
to update the module or give me a patch :)

The way the links are ordered is: POD in the module, links attribute, comment links.

=head1 ATTRIBUTES

=head2 add_main_link

A boolean value controlling whether the link back to the main module should be
added in the submodules.

Defaults to true.

=head2 header

Specify the content to be displayed before the list of links is shown.

The default is a sufficient explanation (see L</SEE ALSO>).

=head2 links

Specify a list of links you want to add to the SEE ALSO section.

You can either specify it like this: "Foo::Bar" or do it in POD format: "L<Foo::Bar>". This
module will automatically add the proper POD formatting if it is missing.

The default is an empty list.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Weaver>

=item *

L<Dist::Zilla>

=back

=for :stopwords CPAN AnnoCPAN RT CPANTS Kwalitee diff IRC

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Pod::Weaver::Section::SeeAlso

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

L<http://search.cpan.org/dist/Pod-Weaver-Section-SeeAlso>

=item *

RT: CPAN's Bug Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Weaver-Section-SeeAlso>

=item *

AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Pod-Weaver-Section-SeeAlso>

=item *

CPAN Ratings

L<http://cpanratings.perl.org/d/Pod-Weaver-Section-SeeAlso>

=item *

CPAN Forum

L<http://cpanforum.com/dist/Pod-Weaver-Section-SeeAlso>

=item *

CPANTS Kwalitee

L<http://cpants.perl.org/dist/overview/Pod-Weaver-Section-SeeAlso>

=item *

CPAN Testers Results

L<http://cpantesters.org/distro/P/Pod-Weaver-Section-SeeAlso.html>

=item *

CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Pod-Weaver-Section-SeeAlso>

=back

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #perl-help then talk to this person for help: Apocalypse.

=item *

irc.freenode.net

You can connect to the server at 'irc.freenode.net' and join this channel: #perl then talk to this person for help: Apocal.

=item *

irc.efnet.org

You can connect to the server at 'irc.efnet.org' and join this channel: #perl then talk to this person for help: Ap0cal.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-pod-weaver-section-seealso at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Weaver-Section-SeeAlso>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/apocalypse/perl-pod-weaver-section-seealso>

  git clone git://github.com/apocalypse/perl-pod-weaver-section-seealso.git

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the LICENSE file included with this distribution.

=cut

