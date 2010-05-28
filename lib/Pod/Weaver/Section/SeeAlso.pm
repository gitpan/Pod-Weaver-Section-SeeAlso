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
  $Pod::Weaver::Section::SeeAlso::VERSION = '0.004';
}
BEGIN {
  $Pod::Weaver::Section::SeeAlso::AUTHORITY = 'cpan:APOCAL';
}

# ABSTRACT: add a SEE ALSO pod section

use Moose 1.01;
use Moose::Autobox 0.10;

use Pod::Weaver::Role::Section 3.100710;
with 'Pod::Weaver::Role::Section';

sub weave_section {
	my ($self, $document, $input) = @_;
	my $zilla = $input->{zilla} or return;

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
					if ( $l !~ /^L\<.+\>$/ ) {
						die 'Unknown POD in SEE ALSO: ' . $l;
					} else {
						push( @links, $l );
					}
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
				if ( $l !~ /^L\<.+\>$/ ) {
					die 'Unknown POD in SEE ALSO: ' . $l;
				} else {
					push( @links, $l );
				}
			}
		}
	}
	if ( ! $is_main ) {
		unshift( @links, "L<$main>" );
	}

	if ( @links ) {
		$document->children->push(
			Pod::Elemental::Element::Nested->new( {
				command => 'head1',
				content => 'SEE ALSO',
				children => [
					# TODO I forgot why I didn't just use the List Transformer... it deserves a follow-up
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
	my( $title, $contents ) = @_;

	my $str = $title;
	if ( defined $contents ) {
		$str .= "\n\n$contents";
	}

	return Pod::Elemental::Element::Nested->new( {
		command => 'item',
		content => '*',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
				content => $str,
			} ),
		],
	} );
}

1;



__END__
=pod

=for Pod::Coverage weave_section

=for stopwords dist dzil

=head1 NAME

Pod::Weaver::Section::SeeAlso - add a SEE ALSO pod section

=head1 VERSION

  This document describes v0.004 of Pod::Weaver::Section::SeeAlso - released May 28, 2010 as part of Pod-Weaver-Section-SeeAlso.

=head1 DESCRIPTION

This section plugin will produce a hunk of pod that references the main module of a dist
from it's submodules and adds any other text already present in the pod. It will do this
only if it is being built with L<Dist::Zilla> because it needs the data from the dzil object.

In the main module, this section plugin just transforms the links into a proper list. In the
submodules, it also adds the link to the main module.

For an example of what the hunk looks like, look at the L</SEE ALSO> section in this POD :)

WARNING: Please do not put any other POD commands in your SEE ALSO section!

What you should do when you want to add extra links is:

	=head1 SEE ALSO
	L<Foo::Bar>
	L<Bar::Baz>

And this module will automatically convert it into:

	=head1 SEE ALSO
	=over 4
	=item *
	L<Main::Module>
	=item *
	L<Foo::Bar>
	=item *
	L<Bar::Baz>
	=back

=head1 SEE ALSO

=over 4

=item *

L<Pod::Weaver>

=item *

L<Dist::Zilla>

=back

=for :stopwords CPAN AnnoCPAN RT CPANTS Kwalitee diff

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Pod::Weaver::Section::SeeAlso

=head2 Websites

=over 4

=item *

Search CPAN

L<http://search.cpan.org/dist/Pod-Weaver-Section-SeeAlso>

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

RT: CPAN's Bug Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Weaver-Section-SeeAlso>

=item *

CPANTS Kwalitee

L<http://cpants.perl.org/dist/overview/Pod-Weaver-Section-SeeAlso>

=item *

CPAN Testers Results

L<http://cpantesters.org/distro/P/Pod-Weaver-Section-SeeAlso.html>

=item *

CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Pod-Weaver-Section-SeeAlso>

=item *

Source Code Repository

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/apocalypse/perl-pod-weaver-section-seealso>

=back

=head2 Bugs

Please report any bugs or feature requests to C<bug-pod-weaver-section-seealso at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Weaver-Section-SeeAlso>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

  Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the F<LICENSE> file included with this distribution.

=cut

